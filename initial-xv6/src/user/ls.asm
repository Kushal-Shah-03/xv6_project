
user/_ls:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <fmtname>:
#include "user/user.h"
#include "kernel/fs.h"

char*
fmtname(char *path)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
   e:	84aa                	mv	s1,a0
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
  10:	00000097          	auipc	ra,0x0
  14:	334080e7          	jalr	820(ra) # 344 <strlen>
  18:	02051793          	slli	a5,a0,0x20
  1c:	9381                	srli	a5,a5,0x20
  1e:	97a6                	add	a5,a5,s1
  20:	02f00693          	li	a3,47
  24:	0097e963          	bltu	a5,s1,36 <fmtname+0x36>
  28:	0007c703          	lbu	a4,0(a5)
  2c:	00d70563          	beq	a4,a3,36 <fmtname+0x36>
  30:	17fd                	addi	a5,a5,-1
  32:	fe97fbe3          	bgeu	a5,s1,28 <fmtname+0x28>
    ;
  p++;
  36:	00178493          	addi	s1,a5,1

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
  3a:	8526                	mv	a0,s1
  3c:	00000097          	auipc	ra,0x0
  40:	308080e7          	jalr	776(ra) # 344 <strlen>
  44:	2501                	sext.w	a0,a0
  46:	47b5                	li	a5,13
  48:	00a7fa63          	bgeu	a5,a0,5c <fmtname+0x5c>
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}
  4c:	8526                	mv	a0,s1
  4e:	70a2                	ld	ra,40(sp)
  50:	7402                	ld	s0,32(sp)
  52:	64e2                	ld	s1,24(sp)
  54:	6942                	ld	s2,16(sp)
  56:	69a2                	ld	s3,8(sp)
  58:	6145                	addi	sp,sp,48
  5a:	8082                	ret
  memmove(buf, p, strlen(p));
  5c:	8526                	mv	a0,s1
  5e:	00000097          	auipc	ra,0x0
  62:	2e6080e7          	jalr	742(ra) # 344 <strlen>
  66:	00001997          	auipc	s3,0x1
  6a:	faa98993          	addi	s3,s3,-86 # 1010 <buf.0>
  6e:	0005061b          	sext.w	a2,a0
  72:	85a6                	mv	a1,s1
  74:	854e                	mv	a0,s3
  76:	00000097          	auipc	ra,0x0
  7a:	442080e7          	jalr	1090(ra) # 4b8 <memmove>
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  7e:	8526                	mv	a0,s1
  80:	00000097          	auipc	ra,0x0
  84:	2c4080e7          	jalr	708(ra) # 344 <strlen>
  88:	0005091b          	sext.w	s2,a0
  8c:	8526                	mv	a0,s1
  8e:	00000097          	auipc	ra,0x0
  92:	2b6080e7          	jalr	694(ra) # 344 <strlen>
  96:	1902                	slli	s2,s2,0x20
  98:	02095913          	srli	s2,s2,0x20
  9c:	4639                	li	a2,14
  9e:	9e09                	subw	a2,a2,a0
  a0:	02000593          	li	a1,32
  a4:	01298533          	add	a0,s3,s2
  a8:	00000097          	auipc	ra,0x0
  ac:	2c6080e7          	jalr	710(ra) # 36e <memset>
  return buf;
  b0:	84ce                	mv	s1,s3
  b2:	bf69                	j	4c <fmtname+0x4c>

00000000000000b4 <ls>:

void
ls(char *path)
{
  b4:	d9010113          	addi	sp,sp,-624
  b8:	26113423          	sd	ra,616(sp)
  bc:	26813023          	sd	s0,608(sp)
  c0:	24913c23          	sd	s1,600(sp)
  c4:	25213823          	sd	s2,592(sp)
  c8:	25313423          	sd	s3,584(sp)
  cc:	25413023          	sd	s4,576(sp)
  d0:	23513c23          	sd	s5,568(sp)
  d4:	1c80                	addi	s0,sp,624
  d6:	892a                	mv	s2,a0
  getreadcount();
  d8:	00000097          	auipc	ra,0x0
  dc:	53a080e7          	jalr	1338(ra) # 612 <getreadcount>
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  if((fd = open(path, 0)) < 0){
  e0:	4581                	li	a1,0
  e2:	854a                	mv	a0,s2
  e4:	00000097          	auipc	ra,0x0
  e8:	4c6080e7          	jalr	1222(ra) # 5aa <open>
  ec:	08054163          	bltz	a0,16e <ls+0xba>
  f0:	84aa                	mv	s1,a0
    fprintf(2, "ls: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
  f2:	d9840593          	addi	a1,s0,-616
  f6:	00000097          	auipc	ra,0x0
  fa:	4cc080e7          	jalr	1228(ra) # 5c2 <fstat>
  fe:	08054363          	bltz	a0,184 <ls+0xd0>
    fprintf(2, "ls: cannot stat %s\n", path);
    close(fd);
    return;
  }

  switch(st.type){
 102:	da041783          	lh	a5,-608(s0)
 106:	0007869b          	sext.w	a3,a5
 10a:	4705                	li	a4,1
 10c:	08e68c63          	beq	a3,a4,1a4 <ls+0xf0>
 110:	37f9                	addiw	a5,a5,-2
 112:	17c2                	slli	a5,a5,0x30
 114:	93c1                	srli	a5,a5,0x30
 116:	02f76663          	bltu	a4,a5,142 <ls+0x8e>
  case T_DEVICE:
  case T_FILE:
    printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
 11a:	854a                	mv	a0,s2
 11c:	00000097          	auipc	ra,0x0
 120:	ee4080e7          	jalr	-284(ra) # 0 <fmtname>
 124:	85aa                	mv	a1,a0
 126:	da843703          	ld	a4,-600(s0)
 12a:	d9c42683          	lw	a3,-612(s0)
 12e:	da041603          	lh	a2,-608(s0)
 132:	00001517          	auipc	a0,0x1
 136:	99e50513          	addi	a0,a0,-1634 # ad0 <malloc+0x120>
 13a:	00000097          	auipc	ra,0x0
 13e:	7b8080e7          	jalr	1976(ra) # 8f2 <printf>
      }
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
  }
  close(fd);
 142:	8526                	mv	a0,s1
 144:	00000097          	auipc	ra,0x0
 148:	44e080e7          	jalr	1102(ra) # 592 <close>
}
 14c:	26813083          	ld	ra,616(sp)
 150:	26013403          	ld	s0,608(sp)
 154:	25813483          	ld	s1,600(sp)
 158:	25013903          	ld	s2,592(sp)
 15c:	24813983          	ld	s3,584(sp)
 160:	24013a03          	ld	s4,576(sp)
 164:	23813a83          	ld	s5,568(sp)
 168:	27010113          	addi	sp,sp,624
 16c:	8082                	ret
    fprintf(2, "ls: cannot open %s\n", path);
 16e:	864a                	mv	a2,s2
 170:	00001597          	auipc	a1,0x1
 174:	93058593          	addi	a1,a1,-1744 # aa0 <malloc+0xf0>
 178:	4509                	li	a0,2
 17a:	00000097          	auipc	ra,0x0
 17e:	74a080e7          	jalr	1866(ra) # 8c4 <fprintf>
    return;
 182:	b7e9                	j	14c <ls+0x98>
    fprintf(2, "ls: cannot stat %s\n", path);
 184:	864a                	mv	a2,s2
 186:	00001597          	auipc	a1,0x1
 18a:	93258593          	addi	a1,a1,-1742 # ab8 <malloc+0x108>
 18e:	4509                	li	a0,2
 190:	00000097          	auipc	ra,0x0
 194:	734080e7          	jalr	1844(ra) # 8c4 <fprintf>
    close(fd);
 198:	8526                	mv	a0,s1
 19a:	00000097          	auipc	ra,0x0
 19e:	3f8080e7          	jalr	1016(ra) # 592 <close>
    return;
 1a2:	b76d                	j	14c <ls+0x98>
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 1a4:	854a                	mv	a0,s2
 1a6:	00000097          	auipc	ra,0x0
 1aa:	19e080e7          	jalr	414(ra) # 344 <strlen>
 1ae:	2541                	addiw	a0,a0,16
 1b0:	20000793          	li	a5,512
 1b4:	00a7fb63          	bgeu	a5,a0,1ca <ls+0x116>
      printf("ls: path too long\n");
 1b8:	00001517          	auipc	a0,0x1
 1bc:	92850513          	addi	a0,a0,-1752 # ae0 <malloc+0x130>
 1c0:	00000097          	auipc	ra,0x0
 1c4:	732080e7          	jalr	1842(ra) # 8f2 <printf>
      break;
 1c8:	bfad                	j	142 <ls+0x8e>
    strcpy(buf, path);
 1ca:	85ca                	mv	a1,s2
 1cc:	dc040513          	addi	a0,s0,-576
 1d0:	00000097          	auipc	ra,0x0
 1d4:	12c080e7          	jalr	300(ra) # 2fc <strcpy>
    p = buf+strlen(buf);
 1d8:	dc040513          	addi	a0,s0,-576
 1dc:	00000097          	auipc	ra,0x0
 1e0:	168080e7          	jalr	360(ra) # 344 <strlen>
 1e4:	02051913          	slli	s2,a0,0x20
 1e8:	02095913          	srli	s2,s2,0x20
 1ec:	dc040793          	addi	a5,s0,-576
 1f0:	993e                	add	s2,s2,a5
    *p++ = '/';
 1f2:	00190993          	addi	s3,s2,1
 1f6:	02f00793          	li	a5,47
 1fa:	00f90023          	sb	a5,0(s2)
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 1fe:	00001a17          	auipc	s4,0x1
 202:	8faa0a13          	addi	s4,s4,-1798 # af8 <malloc+0x148>
        printf("ls: cannot stat %s\n", buf);
 206:	00001a97          	auipc	s5,0x1
 20a:	8b2a8a93          	addi	s5,s5,-1870 # ab8 <malloc+0x108>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 20e:	a801                	j	21e <ls+0x16a>
        printf("ls: cannot stat %s\n", buf);
 210:	dc040593          	addi	a1,s0,-576
 214:	8556                	mv	a0,s5
 216:	00000097          	auipc	ra,0x0
 21a:	6dc080e7          	jalr	1756(ra) # 8f2 <printf>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 21e:	4641                	li	a2,16
 220:	db040593          	addi	a1,s0,-592
 224:	8526                	mv	a0,s1
 226:	00000097          	auipc	ra,0x0
 22a:	35c080e7          	jalr	860(ra) # 582 <read>
 22e:	47c1                	li	a5,16
 230:	f0f519e3          	bne	a0,a5,142 <ls+0x8e>
      if(de.inum == 0)
 234:	db045783          	lhu	a5,-592(s0)
 238:	d3fd                	beqz	a5,21e <ls+0x16a>
      memmove(p, de.name, DIRSIZ);
 23a:	4639                	li	a2,14
 23c:	db240593          	addi	a1,s0,-590
 240:	854e                	mv	a0,s3
 242:	00000097          	auipc	ra,0x0
 246:	276080e7          	jalr	630(ra) # 4b8 <memmove>
      p[DIRSIZ] = 0;
 24a:	000907a3          	sb	zero,15(s2)
      if(stat(buf, &st) < 0){
 24e:	d9840593          	addi	a1,s0,-616
 252:	dc040513          	addi	a0,s0,-576
 256:	00000097          	auipc	ra,0x0
 25a:	1d2080e7          	jalr	466(ra) # 428 <stat>
 25e:	fa0549e3          	bltz	a0,210 <ls+0x15c>
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 262:	dc040513          	addi	a0,s0,-576
 266:	00000097          	auipc	ra,0x0
 26a:	d9a080e7          	jalr	-614(ra) # 0 <fmtname>
 26e:	85aa                	mv	a1,a0
 270:	da843703          	ld	a4,-600(s0)
 274:	d9c42683          	lw	a3,-612(s0)
 278:	da041603          	lh	a2,-608(s0)
 27c:	8552                	mv	a0,s4
 27e:	00000097          	auipc	ra,0x0
 282:	674080e7          	jalr	1652(ra) # 8f2 <printf>
 286:	bf61                	j	21e <ls+0x16a>

0000000000000288 <main>:

int
main(int argc, char *argv[])
{
 288:	1101                	addi	sp,sp,-32
 28a:	ec06                	sd	ra,24(sp)
 28c:	e822                	sd	s0,16(sp)
 28e:	e426                	sd	s1,8(sp)
 290:	e04a                	sd	s2,0(sp)
 292:	1000                	addi	s0,sp,32
  int i;

  if(argc < 2){
 294:	4785                	li	a5,1
 296:	02a7d963          	bge	a5,a0,2c8 <main+0x40>
 29a:	00858493          	addi	s1,a1,8
 29e:	ffe5091b          	addiw	s2,a0,-2
 2a2:	1902                	slli	s2,s2,0x20
 2a4:	02095913          	srli	s2,s2,0x20
 2a8:	090e                	slli	s2,s2,0x3
 2aa:	05c1                	addi	a1,a1,16
 2ac:	992e                	add	s2,s2,a1
    ls(".");
    exit(0);
  }
  for(i=1; i<argc; i++)
    ls(argv[i]);
 2ae:	6088                	ld	a0,0(s1)
 2b0:	00000097          	auipc	ra,0x0
 2b4:	e04080e7          	jalr	-508(ra) # b4 <ls>
  for(i=1; i<argc; i++)
 2b8:	04a1                	addi	s1,s1,8
 2ba:	ff249ae3          	bne	s1,s2,2ae <main+0x26>
  exit(0);
 2be:	4501                	li	a0,0
 2c0:	00000097          	auipc	ra,0x0
 2c4:	2aa080e7          	jalr	682(ra) # 56a <exit>
    ls(".");
 2c8:	00001517          	auipc	a0,0x1
 2cc:	84050513          	addi	a0,a0,-1984 # b08 <malloc+0x158>
 2d0:	00000097          	auipc	ra,0x0
 2d4:	de4080e7          	jalr	-540(ra) # b4 <ls>
    exit(0);
 2d8:	4501                	li	a0,0
 2da:	00000097          	auipc	ra,0x0
 2de:	290080e7          	jalr	656(ra) # 56a <exit>

00000000000002e2 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 2e2:	1141                	addi	sp,sp,-16
 2e4:	e406                	sd	ra,8(sp)
 2e6:	e022                	sd	s0,0(sp)
 2e8:	0800                	addi	s0,sp,16
  extern int main();
  main();
 2ea:	00000097          	auipc	ra,0x0
 2ee:	f9e080e7          	jalr	-98(ra) # 288 <main>
  exit(0);
 2f2:	4501                	li	a0,0
 2f4:	00000097          	auipc	ra,0x0
 2f8:	276080e7          	jalr	630(ra) # 56a <exit>

00000000000002fc <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 2fc:	1141                	addi	sp,sp,-16
 2fe:	e422                	sd	s0,8(sp)
 300:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 302:	87aa                	mv	a5,a0
 304:	0585                	addi	a1,a1,1
 306:	0785                	addi	a5,a5,1
 308:	fff5c703          	lbu	a4,-1(a1)
 30c:	fee78fa3          	sb	a4,-1(a5)
 310:	fb75                	bnez	a4,304 <strcpy+0x8>
    ;
  return os;
}
 312:	6422                	ld	s0,8(sp)
 314:	0141                	addi	sp,sp,16
 316:	8082                	ret

0000000000000318 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 318:	1141                	addi	sp,sp,-16
 31a:	e422                	sd	s0,8(sp)
 31c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 31e:	00054783          	lbu	a5,0(a0)
 322:	cb91                	beqz	a5,336 <strcmp+0x1e>
 324:	0005c703          	lbu	a4,0(a1)
 328:	00f71763          	bne	a4,a5,336 <strcmp+0x1e>
    p++, q++;
 32c:	0505                	addi	a0,a0,1
 32e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 330:	00054783          	lbu	a5,0(a0)
 334:	fbe5                	bnez	a5,324 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 336:	0005c503          	lbu	a0,0(a1)
}
 33a:	40a7853b          	subw	a0,a5,a0
 33e:	6422                	ld	s0,8(sp)
 340:	0141                	addi	sp,sp,16
 342:	8082                	ret

0000000000000344 <strlen>:

uint
strlen(const char *s)
{
 344:	1141                	addi	sp,sp,-16
 346:	e422                	sd	s0,8(sp)
 348:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 34a:	00054783          	lbu	a5,0(a0)
 34e:	cf91                	beqz	a5,36a <strlen+0x26>
 350:	0505                	addi	a0,a0,1
 352:	87aa                	mv	a5,a0
 354:	4685                	li	a3,1
 356:	9e89                	subw	a3,a3,a0
 358:	00f6853b          	addw	a0,a3,a5
 35c:	0785                	addi	a5,a5,1
 35e:	fff7c703          	lbu	a4,-1(a5)
 362:	fb7d                	bnez	a4,358 <strlen+0x14>
    ;
  return n;
}
 364:	6422                	ld	s0,8(sp)
 366:	0141                	addi	sp,sp,16
 368:	8082                	ret
  for(n = 0; s[n]; n++)
 36a:	4501                	li	a0,0
 36c:	bfe5                	j	364 <strlen+0x20>

000000000000036e <memset>:

void*
memset(void *dst, int c, uint n)
{
 36e:	1141                	addi	sp,sp,-16
 370:	e422                	sd	s0,8(sp)
 372:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 374:	ca19                	beqz	a2,38a <memset+0x1c>
 376:	87aa                	mv	a5,a0
 378:	1602                	slli	a2,a2,0x20
 37a:	9201                	srli	a2,a2,0x20
 37c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 380:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 384:	0785                	addi	a5,a5,1
 386:	fee79de3          	bne	a5,a4,380 <memset+0x12>
  }
  return dst;
}
 38a:	6422                	ld	s0,8(sp)
 38c:	0141                	addi	sp,sp,16
 38e:	8082                	ret

0000000000000390 <strchr>:

char*
strchr(const char *s, char c)
{
 390:	1141                	addi	sp,sp,-16
 392:	e422                	sd	s0,8(sp)
 394:	0800                	addi	s0,sp,16
  for(; *s; s++)
 396:	00054783          	lbu	a5,0(a0)
 39a:	cb99                	beqz	a5,3b0 <strchr+0x20>
    if(*s == c)
 39c:	00f58763          	beq	a1,a5,3aa <strchr+0x1a>
  for(; *s; s++)
 3a0:	0505                	addi	a0,a0,1
 3a2:	00054783          	lbu	a5,0(a0)
 3a6:	fbfd                	bnez	a5,39c <strchr+0xc>
      return (char*)s;
  return 0;
 3a8:	4501                	li	a0,0
}
 3aa:	6422                	ld	s0,8(sp)
 3ac:	0141                	addi	sp,sp,16
 3ae:	8082                	ret
  return 0;
 3b0:	4501                	li	a0,0
 3b2:	bfe5                	j	3aa <strchr+0x1a>

00000000000003b4 <gets>:

char*
gets(char *buf, int max)
{
 3b4:	711d                	addi	sp,sp,-96
 3b6:	ec86                	sd	ra,88(sp)
 3b8:	e8a2                	sd	s0,80(sp)
 3ba:	e4a6                	sd	s1,72(sp)
 3bc:	e0ca                	sd	s2,64(sp)
 3be:	fc4e                	sd	s3,56(sp)
 3c0:	f852                	sd	s4,48(sp)
 3c2:	f456                	sd	s5,40(sp)
 3c4:	f05a                	sd	s6,32(sp)
 3c6:	ec5e                	sd	s7,24(sp)
 3c8:	1080                	addi	s0,sp,96
 3ca:	8baa                	mv	s7,a0
 3cc:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3ce:	892a                	mv	s2,a0
 3d0:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3d2:	4aa9                	li	s5,10
 3d4:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3d6:	89a6                	mv	s3,s1
 3d8:	2485                	addiw	s1,s1,1
 3da:	0344d863          	bge	s1,s4,40a <gets+0x56>
    cc = read(0, &c, 1);
 3de:	4605                	li	a2,1
 3e0:	faf40593          	addi	a1,s0,-81
 3e4:	4501                	li	a0,0
 3e6:	00000097          	auipc	ra,0x0
 3ea:	19c080e7          	jalr	412(ra) # 582 <read>
    if(cc < 1)
 3ee:	00a05e63          	blez	a0,40a <gets+0x56>
    buf[i++] = c;
 3f2:	faf44783          	lbu	a5,-81(s0)
 3f6:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3fa:	01578763          	beq	a5,s5,408 <gets+0x54>
 3fe:	0905                	addi	s2,s2,1
 400:	fd679be3          	bne	a5,s6,3d6 <gets+0x22>
  for(i=0; i+1 < max; ){
 404:	89a6                	mv	s3,s1
 406:	a011                	j	40a <gets+0x56>
 408:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 40a:	99de                	add	s3,s3,s7
 40c:	00098023          	sb	zero,0(s3)
  return buf;
}
 410:	855e                	mv	a0,s7
 412:	60e6                	ld	ra,88(sp)
 414:	6446                	ld	s0,80(sp)
 416:	64a6                	ld	s1,72(sp)
 418:	6906                	ld	s2,64(sp)
 41a:	79e2                	ld	s3,56(sp)
 41c:	7a42                	ld	s4,48(sp)
 41e:	7aa2                	ld	s5,40(sp)
 420:	7b02                	ld	s6,32(sp)
 422:	6be2                	ld	s7,24(sp)
 424:	6125                	addi	sp,sp,96
 426:	8082                	ret

0000000000000428 <stat>:

int
stat(const char *n, struct stat *st)
{
 428:	1101                	addi	sp,sp,-32
 42a:	ec06                	sd	ra,24(sp)
 42c:	e822                	sd	s0,16(sp)
 42e:	e426                	sd	s1,8(sp)
 430:	e04a                	sd	s2,0(sp)
 432:	1000                	addi	s0,sp,32
 434:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 436:	4581                	li	a1,0
 438:	00000097          	auipc	ra,0x0
 43c:	172080e7          	jalr	370(ra) # 5aa <open>
  if(fd < 0)
 440:	02054563          	bltz	a0,46a <stat+0x42>
 444:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 446:	85ca                	mv	a1,s2
 448:	00000097          	auipc	ra,0x0
 44c:	17a080e7          	jalr	378(ra) # 5c2 <fstat>
 450:	892a                	mv	s2,a0
  close(fd);
 452:	8526                	mv	a0,s1
 454:	00000097          	auipc	ra,0x0
 458:	13e080e7          	jalr	318(ra) # 592 <close>
  return r;
}
 45c:	854a                	mv	a0,s2
 45e:	60e2                	ld	ra,24(sp)
 460:	6442                	ld	s0,16(sp)
 462:	64a2                	ld	s1,8(sp)
 464:	6902                	ld	s2,0(sp)
 466:	6105                	addi	sp,sp,32
 468:	8082                	ret
    return -1;
 46a:	597d                	li	s2,-1
 46c:	bfc5                	j	45c <stat+0x34>

000000000000046e <atoi>:

int
atoi(const char *s)
{
 46e:	1141                	addi	sp,sp,-16
 470:	e422                	sd	s0,8(sp)
 472:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 474:	00054603          	lbu	a2,0(a0)
 478:	fd06079b          	addiw	a5,a2,-48
 47c:	0ff7f793          	andi	a5,a5,255
 480:	4725                	li	a4,9
 482:	02f76963          	bltu	a4,a5,4b4 <atoi+0x46>
 486:	86aa                	mv	a3,a0
  n = 0;
 488:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 48a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 48c:	0685                	addi	a3,a3,1
 48e:	0025179b          	slliw	a5,a0,0x2
 492:	9fa9                	addw	a5,a5,a0
 494:	0017979b          	slliw	a5,a5,0x1
 498:	9fb1                	addw	a5,a5,a2
 49a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 49e:	0006c603          	lbu	a2,0(a3)
 4a2:	fd06071b          	addiw	a4,a2,-48
 4a6:	0ff77713          	andi	a4,a4,255
 4aa:	fee5f1e3          	bgeu	a1,a4,48c <atoi+0x1e>
  return n;
}
 4ae:	6422                	ld	s0,8(sp)
 4b0:	0141                	addi	sp,sp,16
 4b2:	8082                	ret
  n = 0;
 4b4:	4501                	li	a0,0
 4b6:	bfe5                	j	4ae <atoi+0x40>

00000000000004b8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 4b8:	1141                	addi	sp,sp,-16
 4ba:	e422                	sd	s0,8(sp)
 4bc:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4be:	02b57463          	bgeu	a0,a1,4e6 <memmove+0x2e>
    while(n-- > 0)
 4c2:	00c05f63          	blez	a2,4e0 <memmove+0x28>
 4c6:	1602                	slli	a2,a2,0x20
 4c8:	9201                	srli	a2,a2,0x20
 4ca:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 4ce:	872a                	mv	a4,a0
      *dst++ = *src++;
 4d0:	0585                	addi	a1,a1,1
 4d2:	0705                	addi	a4,a4,1
 4d4:	fff5c683          	lbu	a3,-1(a1)
 4d8:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4dc:	fee79ae3          	bne	a5,a4,4d0 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4e0:	6422                	ld	s0,8(sp)
 4e2:	0141                	addi	sp,sp,16
 4e4:	8082                	ret
    dst += n;
 4e6:	00c50733          	add	a4,a0,a2
    src += n;
 4ea:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4ec:	fec05ae3          	blez	a2,4e0 <memmove+0x28>
 4f0:	fff6079b          	addiw	a5,a2,-1
 4f4:	1782                	slli	a5,a5,0x20
 4f6:	9381                	srli	a5,a5,0x20
 4f8:	fff7c793          	not	a5,a5
 4fc:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4fe:	15fd                	addi	a1,a1,-1
 500:	177d                	addi	a4,a4,-1
 502:	0005c683          	lbu	a3,0(a1)
 506:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 50a:	fee79ae3          	bne	a5,a4,4fe <memmove+0x46>
 50e:	bfc9                	j	4e0 <memmove+0x28>

0000000000000510 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 510:	1141                	addi	sp,sp,-16
 512:	e422                	sd	s0,8(sp)
 514:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 516:	ca05                	beqz	a2,546 <memcmp+0x36>
 518:	fff6069b          	addiw	a3,a2,-1
 51c:	1682                	slli	a3,a3,0x20
 51e:	9281                	srli	a3,a3,0x20
 520:	0685                	addi	a3,a3,1
 522:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 524:	00054783          	lbu	a5,0(a0)
 528:	0005c703          	lbu	a4,0(a1)
 52c:	00e79863          	bne	a5,a4,53c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 530:	0505                	addi	a0,a0,1
    p2++;
 532:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 534:	fed518e3          	bne	a0,a3,524 <memcmp+0x14>
  }
  return 0;
 538:	4501                	li	a0,0
 53a:	a019                	j	540 <memcmp+0x30>
      return *p1 - *p2;
 53c:	40e7853b          	subw	a0,a5,a4
}
 540:	6422                	ld	s0,8(sp)
 542:	0141                	addi	sp,sp,16
 544:	8082                	ret
  return 0;
 546:	4501                	li	a0,0
 548:	bfe5                	j	540 <memcmp+0x30>

000000000000054a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 54a:	1141                	addi	sp,sp,-16
 54c:	e406                	sd	ra,8(sp)
 54e:	e022                	sd	s0,0(sp)
 550:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 552:	00000097          	auipc	ra,0x0
 556:	f66080e7          	jalr	-154(ra) # 4b8 <memmove>
}
 55a:	60a2                	ld	ra,8(sp)
 55c:	6402                	ld	s0,0(sp)
 55e:	0141                	addi	sp,sp,16
 560:	8082                	ret

0000000000000562 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 562:	4885                	li	a7,1
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <exit>:
.global exit
exit:
 li a7, SYS_exit
 56a:	4889                	li	a7,2
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <wait>:
.global wait
wait:
 li a7, SYS_wait
 572:	488d                	li	a7,3
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 57a:	4891                	li	a7,4
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <read>:
.global read
read:
 li a7, SYS_read
 582:	4895                	li	a7,5
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <write>:
.global write
write:
 li a7, SYS_write
 58a:	48c1                	li	a7,16
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <close>:
.global close
close:
 li a7, SYS_close
 592:	48d5                	li	a7,21
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <kill>:
.global kill
kill:
 li a7, SYS_kill
 59a:	4899                	li	a7,6
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <exec>:
.global exec
exec:
 li a7, SYS_exec
 5a2:	489d                	li	a7,7
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <open>:
.global open
open:
 li a7, SYS_open
 5aa:	48bd                	li	a7,15
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5b2:	48c5                	li	a7,17
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5ba:	48c9                	li	a7,18
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5c2:	48a1                	li	a7,8
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <link>:
.global link
link:
 li a7, SYS_link
 5ca:	48cd                	li	a7,19
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5d2:	48d1                	li	a7,20
 ecall
 5d4:	00000073          	ecall
 ret
 5d8:	8082                	ret

00000000000005da <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5da:	48a5                	li	a7,9
 ecall
 5dc:	00000073          	ecall
 ret
 5e0:	8082                	ret

00000000000005e2 <dup>:
.global dup
dup:
 li a7, SYS_dup
 5e2:	48a9                	li	a7,10
 ecall
 5e4:	00000073          	ecall
 ret
 5e8:	8082                	ret

00000000000005ea <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5ea:	48ad                	li	a7,11
 ecall
 5ec:	00000073          	ecall
 ret
 5f0:	8082                	ret

00000000000005f2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5f2:	48b1                	li	a7,12
 ecall
 5f4:	00000073          	ecall
 ret
 5f8:	8082                	ret

00000000000005fa <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5fa:	48b5                	li	a7,13
 ecall
 5fc:	00000073          	ecall
 ret
 600:	8082                	ret

0000000000000602 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 602:	48b9                	li	a7,14
 ecall
 604:	00000073          	ecall
 ret
 608:	8082                	ret

000000000000060a <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 60a:	48d9                	li	a7,22
 ecall
 60c:	00000073          	ecall
 ret
 610:	8082                	ret

0000000000000612 <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 612:	48dd                	li	a7,23
 ecall
 614:	00000073          	ecall
 ret
 618:	8082                	ret

000000000000061a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 61a:	1101                	addi	sp,sp,-32
 61c:	ec06                	sd	ra,24(sp)
 61e:	e822                	sd	s0,16(sp)
 620:	1000                	addi	s0,sp,32
 622:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 626:	4605                	li	a2,1
 628:	fef40593          	addi	a1,s0,-17
 62c:	00000097          	auipc	ra,0x0
 630:	f5e080e7          	jalr	-162(ra) # 58a <write>
}
 634:	60e2                	ld	ra,24(sp)
 636:	6442                	ld	s0,16(sp)
 638:	6105                	addi	sp,sp,32
 63a:	8082                	ret

000000000000063c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 63c:	7139                	addi	sp,sp,-64
 63e:	fc06                	sd	ra,56(sp)
 640:	f822                	sd	s0,48(sp)
 642:	f426                	sd	s1,40(sp)
 644:	f04a                	sd	s2,32(sp)
 646:	ec4e                	sd	s3,24(sp)
 648:	0080                	addi	s0,sp,64
 64a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 64c:	c299                	beqz	a3,652 <printint+0x16>
 64e:	0805c863          	bltz	a1,6de <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 652:	2581                	sext.w	a1,a1
  neg = 0;
 654:	4881                	li	a7,0
 656:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 65a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 65c:	2601                	sext.w	a2,a2
 65e:	00000517          	auipc	a0,0x0
 662:	4ba50513          	addi	a0,a0,1210 # b18 <digits>
 666:	883a                	mv	a6,a4
 668:	2705                	addiw	a4,a4,1
 66a:	02c5f7bb          	remuw	a5,a1,a2
 66e:	1782                	slli	a5,a5,0x20
 670:	9381                	srli	a5,a5,0x20
 672:	97aa                	add	a5,a5,a0
 674:	0007c783          	lbu	a5,0(a5)
 678:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 67c:	0005879b          	sext.w	a5,a1
 680:	02c5d5bb          	divuw	a1,a1,a2
 684:	0685                	addi	a3,a3,1
 686:	fec7f0e3          	bgeu	a5,a2,666 <printint+0x2a>
  if(neg)
 68a:	00088b63          	beqz	a7,6a0 <printint+0x64>
    buf[i++] = '-';
 68e:	fd040793          	addi	a5,s0,-48
 692:	973e                	add	a4,a4,a5
 694:	02d00793          	li	a5,45
 698:	fef70823          	sb	a5,-16(a4)
 69c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6a0:	02e05863          	blez	a4,6d0 <printint+0x94>
 6a4:	fc040793          	addi	a5,s0,-64
 6a8:	00e78933          	add	s2,a5,a4
 6ac:	fff78993          	addi	s3,a5,-1
 6b0:	99ba                	add	s3,s3,a4
 6b2:	377d                	addiw	a4,a4,-1
 6b4:	1702                	slli	a4,a4,0x20
 6b6:	9301                	srli	a4,a4,0x20
 6b8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6bc:	fff94583          	lbu	a1,-1(s2)
 6c0:	8526                	mv	a0,s1
 6c2:	00000097          	auipc	ra,0x0
 6c6:	f58080e7          	jalr	-168(ra) # 61a <putc>
  while(--i >= 0)
 6ca:	197d                	addi	s2,s2,-1
 6cc:	ff3918e3          	bne	s2,s3,6bc <printint+0x80>
}
 6d0:	70e2                	ld	ra,56(sp)
 6d2:	7442                	ld	s0,48(sp)
 6d4:	74a2                	ld	s1,40(sp)
 6d6:	7902                	ld	s2,32(sp)
 6d8:	69e2                	ld	s3,24(sp)
 6da:	6121                	addi	sp,sp,64
 6dc:	8082                	ret
    x = -xx;
 6de:	40b005bb          	negw	a1,a1
    neg = 1;
 6e2:	4885                	li	a7,1
    x = -xx;
 6e4:	bf8d                	j	656 <printint+0x1a>

00000000000006e6 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6e6:	7119                	addi	sp,sp,-128
 6e8:	fc86                	sd	ra,120(sp)
 6ea:	f8a2                	sd	s0,112(sp)
 6ec:	f4a6                	sd	s1,104(sp)
 6ee:	f0ca                	sd	s2,96(sp)
 6f0:	ecce                	sd	s3,88(sp)
 6f2:	e8d2                	sd	s4,80(sp)
 6f4:	e4d6                	sd	s5,72(sp)
 6f6:	e0da                	sd	s6,64(sp)
 6f8:	fc5e                	sd	s7,56(sp)
 6fa:	f862                	sd	s8,48(sp)
 6fc:	f466                	sd	s9,40(sp)
 6fe:	f06a                	sd	s10,32(sp)
 700:	ec6e                	sd	s11,24(sp)
 702:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 704:	0005c903          	lbu	s2,0(a1)
 708:	18090f63          	beqz	s2,8a6 <vprintf+0x1c0>
 70c:	8aaa                	mv	s5,a0
 70e:	8b32                	mv	s6,a2
 710:	00158493          	addi	s1,a1,1
  state = 0;
 714:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 716:	02500a13          	li	s4,37
      if(c == 'd'){
 71a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 71e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 722:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 726:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 72a:	00000b97          	auipc	s7,0x0
 72e:	3eeb8b93          	addi	s7,s7,1006 # b18 <digits>
 732:	a839                	j	750 <vprintf+0x6a>
        putc(fd, c);
 734:	85ca                	mv	a1,s2
 736:	8556                	mv	a0,s5
 738:	00000097          	auipc	ra,0x0
 73c:	ee2080e7          	jalr	-286(ra) # 61a <putc>
 740:	a019                	j	746 <vprintf+0x60>
    } else if(state == '%'){
 742:	01498f63          	beq	s3,s4,760 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 746:	0485                	addi	s1,s1,1
 748:	fff4c903          	lbu	s2,-1(s1)
 74c:	14090d63          	beqz	s2,8a6 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 750:	0009079b          	sext.w	a5,s2
    if(state == 0){
 754:	fe0997e3          	bnez	s3,742 <vprintf+0x5c>
      if(c == '%'){
 758:	fd479ee3          	bne	a5,s4,734 <vprintf+0x4e>
        state = '%';
 75c:	89be                	mv	s3,a5
 75e:	b7e5                	j	746 <vprintf+0x60>
      if(c == 'd'){
 760:	05878063          	beq	a5,s8,7a0 <vprintf+0xba>
      } else if(c == 'l') {
 764:	05978c63          	beq	a5,s9,7bc <vprintf+0xd6>
      } else if(c == 'x') {
 768:	07a78863          	beq	a5,s10,7d8 <vprintf+0xf2>
      } else if(c == 'p') {
 76c:	09b78463          	beq	a5,s11,7f4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 770:	07300713          	li	a4,115
 774:	0ce78663          	beq	a5,a4,840 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 778:	06300713          	li	a4,99
 77c:	0ee78e63          	beq	a5,a4,878 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 780:	11478863          	beq	a5,s4,890 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 784:	85d2                	mv	a1,s4
 786:	8556                	mv	a0,s5
 788:	00000097          	auipc	ra,0x0
 78c:	e92080e7          	jalr	-366(ra) # 61a <putc>
        putc(fd, c);
 790:	85ca                	mv	a1,s2
 792:	8556                	mv	a0,s5
 794:	00000097          	auipc	ra,0x0
 798:	e86080e7          	jalr	-378(ra) # 61a <putc>
      }
      state = 0;
 79c:	4981                	li	s3,0
 79e:	b765                	j	746 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 7a0:	008b0913          	addi	s2,s6,8
 7a4:	4685                	li	a3,1
 7a6:	4629                	li	a2,10
 7a8:	000b2583          	lw	a1,0(s6)
 7ac:	8556                	mv	a0,s5
 7ae:	00000097          	auipc	ra,0x0
 7b2:	e8e080e7          	jalr	-370(ra) # 63c <printint>
 7b6:	8b4a                	mv	s6,s2
      state = 0;
 7b8:	4981                	li	s3,0
 7ba:	b771                	j	746 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7bc:	008b0913          	addi	s2,s6,8
 7c0:	4681                	li	a3,0
 7c2:	4629                	li	a2,10
 7c4:	000b2583          	lw	a1,0(s6)
 7c8:	8556                	mv	a0,s5
 7ca:	00000097          	auipc	ra,0x0
 7ce:	e72080e7          	jalr	-398(ra) # 63c <printint>
 7d2:	8b4a                	mv	s6,s2
      state = 0;
 7d4:	4981                	li	s3,0
 7d6:	bf85                	j	746 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7d8:	008b0913          	addi	s2,s6,8
 7dc:	4681                	li	a3,0
 7de:	4641                	li	a2,16
 7e0:	000b2583          	lw	a1,0(s6)
 7e4:	8556                	mv	a0,s5
 7e6:	00000097          	auipc	ra,0x0
 7ea:	e56080e7          	jalr	-426(ra) # 63c <printint>
 7ee:	8b4a                	mv	s6,s2
      state = 0;
 7f0:	4981                	li	s3,0
 7f2:	bf91                	j	746 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7f4:	008b0793          	addi	a5,s6,8
 7f8:	f8f43423          	sd	a5,-120(s0)
 7fc:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 800:	03000593          	li	a1,48
 804:	8556                	mv	a0,s5
 806:	00000097          	auipc	ra,0x0
 80a:	e14080e7          	jalr	-492(ra) # 61a <putc>
  putc(fd, 'x');
 80e:	85ea                	mv	a1,s10
 810:	8556                	mv	a0,s5
 812:	00000097          	auipc	ra,0x0
 816:	e08080e7          	jalr	-504(ra) # 61a <putc>
 81a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 81c:	03c9d793          	srli	a5,s3,0x3c
 820:	97de                	add	a5,a5,s7
 822:	0007c583          	lbu	a1,0(a5)
 826:	8556                	mv	a0,s5
 828:	00000097          	auipc	ra,0x0
 82c:	df2080e7          	jalr	-526(ra) # 61a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 830:	0992                	slli	s3,s3,0x4
 832:	397d                	addiw	s2,s2,-1
 834:	fe0914e3          	bnez	s2,81c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 838:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 83c:	4981                	li	s3,0
 83e:	b721                	j	746 <vprintf+0x60>
        s = va_arg(ap, char*);
 840:	008b0993          	addi	s3,s6,8
 844:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 848:	02090163          	beqz	s2,86a <vprintf+0x184>
        while(*s != 0){
 84c:	00094583          	lbu	a1,0(s2)
 850:	c9a1                	beqz	a1,8a0 <vprintf+0x1ba>
          putc(fd, *s);
 852:	8556                	mv	a0,s5
 854:	00000097          	auipc	ra,0x0
 858:	dc6080e7          	jalr	-570(ra) # 61a <putc>
          s++;
 85c:	0905                	addi	s2,s2,1
        while(*s != 0){
 85e:	00094583          	lbu	a1,0(s2)
 862:	f9e5                	bnez	a1,852 <vprintf+0x16c>
        s = va_arg(ap, char*);
 864:	8b4e                	mv	s6,s3
      state = 0;
 866:	4981                	li	s3,0
 868:	bdf9                	j	746 <vprintf+0x60>
          s = "(null)";
 86a:	00000917          	auipc	s2,0x0
 86e:	2a690913          	addi	s2,s2,678 # b10 <malloc+0x160>
        while(*s != 0){
 872:	02800593          	li	a1,40
 876:	bff1                	j	852 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 878:	008b0913          	addi	s2,s6,8
 87c:	000b4583          	lbu	a1,0(s6)
 880:	8556                	mv	a0,s5
 882:	00000097          	auipc	ra,0x0
 886:	d98080e7          	jalr	-616(ra) # 61a <putc>
 88a:	8b4a                	mv	s6,s2
      state = 0;
 88c:	4981                	li	s3,0
 88e:	bd65                	j	746 <vprintf+0x60>
        putc(fd, c);
 890:	85d2                	mv	a1,s4
 892:	8556                	mv	a0,s5
 894:	00000097          	auipc	ra,0x0
 898:	d86080e7          	jalr	-634(ra) # 61a <putc>
      state = 0;
 89c:	4981                	li	s3,0
 89e:	b565                	j	746 <vprintf+0x60>
        s = va_arg(ap, char*);
 8a0:	8b4e                	mv	s6,s3
      state = 0;
 8a2:	4981                	li	s3,0
 8a4:	b54d                	j	746 <vprintf+0x60>
    }
  }
}
 8a6:	70e6                	ld	ra,120(sp)
 8a8:	7446                	ld	s0,112(sp)
 8aa:	74a6                	ld	s1,104(sp)
 8ac:	7906                	ld	s2,96(sp)
 8ae:	69e6                	ld	s3,88(sp)
 8b0:	6a46                	ld	s4,80(sp)
 8b2:	6aa6                	ld	s5,72(sp)
 8b4:	6b06                	ld	s6,64(sp)
 8b6:	7be2                	ld	s7,56(sp)
 8b8:	7c42                	ld	s8,48(sp)
 8ba:	7ca2                	ld	s9,40(sp)
 8bc:	7d02                	ld	s10,32(sp)
 8be:	6de2                	ld	s11,24(sp)
 8c0:	6109                	addi	sp,sp,128
 8c2:	8082                	ret

00000000000008c4 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8c4:	715d                	addi	sp,sp,-80
 8c6:	ec06                	sd	ra,24(sp)
 8c8:	e822                	sd	s0,16(sp)
 8ca:	1000                	addi	s0,sp,32
 8cc:	e010                	sd	a2,0(s0)
 8ce:	e414                	sd	a3,8(s0)
 8d0:	e818                	sd	a4,16(s0)
 8d2:	ec1c                	sd	a5,24(s0)
 8d4:	03043023          	sd	a6,32(s0)
 8d8:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8dc:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8e0:	8622                	mv	a2,s0
 8e2:	00000097          	auipc	ra,0x0
 8e6:	e04080e7          	jalr	-508(ra) # 6e6 <vprintf>
}
 8ea:	60e2                	ld	ra,24(sp)
 8ec:	6442                	ld	s0,16(sp)
 8ee:	6161                	addi	sp,sp,80
 8f0:	8082                	ret

00000000000008f2 <printf>:

void
printf(const char *fmt, ...)
{
 8f2:	711d                	addi	sp,sp,-96
 8f4:	ec06                	sd	ra,24(sp)
 8f6:	e822                	sd	s0,16(sp)
 8f8:	1000                	addi	s0,sp,32
 8fa:	e40c                	sd	a1,8(s0)
 8fc:	e810                	sd	a2,16(s0)
 8fe:	ec14                	sd	a3,24(s0)
 900:	f018                	sd	a4,32(s0)
 902:	f41c                	sd	a5,40(s0)
 904:	03043823          	sd	a6,48(s0)
 908:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 90c:	00840613          	addi	a2,s0,8
 910:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 914:	85aa                	mv	a1,a0
 916:	4505                	li	a0,1
 918:	00000097          	auipc	ra,0x0
 91c:	dce080e7          	jalr	-562(ra) # 6e6 <vprintf>
}
 920:	60e2                	ld	ra,24(sp)
 922:	6442                	ld	s0,16(sp)
 924:	6125                	addi	sp,sp,96
 926:	8082                	ret

0000000000000928 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 928:	1141                	addi	sp,sp,-16
 92a:	e422                	sd	s0,8(sp)
 92c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 92e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 932:	00000797          	auipc	a5,0x0
 936:	6ce7b783          	ld	a5,1742(a5) # 1000 <freep>
 93a:	a805                	j	96a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 93c:	4618                	lw	a4,8(a2)
 93e:	9db9                	addw	a1,a1,a4
 940:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 944:	6398                	ld	a4,0(a5)
 946:	6318                	ld	a4,0(a4)
 948:	fee53823          	sd	a4,-16(a0)
 94c:	a091                	j	990 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 94e:	ff852703          	lw	a4,-8(a0)
 952:	9e39                	addw	a2,a2,a4
 954:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 956:	ff053703          	ld	a4,-16(a0)
 95a:	e398                	sd	a4,0(a5)
 95c:	a099                	j	9a2 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 95e:	6398                	ld	a4,0(a5)
 960:	00e7e463          	bltu	a5,a4,968 <free+0x40>
 964:	00e6ea63          	bltu	a3,a4,978 <free+0x50>
{
 968:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 96a:	fed7fae3          	bgeu	a5,a3,95e <free+0x36>
 96e:	6398                	ld	a4,0(a5)
 970:	00e6e463          	bltu	a3,a4,978 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 974:	fee7eae3          	bltu	a5,a4,968 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 978:	ff852583          	lw	a1,-8(a0)
 97c:	6390                	ld	a2,0(a5)
 97e:	02059713          	slli	a4,a1,0x20
 982:	9301                	srli	a4,a4,0x20
 984:	0712                	slli	a4,a4,0x4
 986:	9736                	add	a4,a4,a3
 988:	fae60ae3          	beq	a2,a4,93c <free+0x14>
    bp->s.ptr = p->s.ptr;
 98c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 990:	4790                	lw	a2,8(a5)
 992:	02061713          	slli	a4,a2,0x20
 996:	9301                	srli	a4,a4,0x20
 998:	0712                	slli	a4,a4,0x4
 99a:	973e                	add	a4,a4,a5
 99c:	fae689e3          	beq	a3,a4,94e <free+0x26>
  } else
    p->s.ptr = bp;
 9a0:	e394                	sd	a3,0(a5)
  freep = p;
 9a2:	00000717          	auipc	a4,0x0
 9a6:	64f73f23          	sd	a5,1630(a4) # 1000 <freep>
}
 9aa:	6422                	ld	s0,8(sp)
 9ac:	0141                	addi	sp,sp,16
 9ae:	8082                	ret

00000000000009b0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9b0:	7139                	addi	sp,sp,-64
 9b2:	fc06                	sd	ra,56(sp)
 9b4:	f822                	sd	s0,48(sp)
 9b6:	f426                	sd	s1,40(sp)
 9b8:	f04a                	sd	s2,32(sp)
 9ba:	ec4e                	sd	s3,24(sp)
 9bc:	e852                	sd	s4,16(sp)
 9be:	e456                	sd	s5,8(sp)
 9c0:	e05a                	sd	s6,0(sp)
 9c2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9c4:	02051493          	slli	s1,a0,0x20
 9c8:	9081                	srli	s1,s1,0x20
 9ca:	04bd                	addi	s1,s1,15
 9cc:	8091                	srli	s1,s1,0x4
 9ce:	0014899b          	addiw	s3,s1,1
 9d2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9d4:	00000517          	auipc	a0,0x0
 9d8:	62c53503          	ld	a0,1580(a0) # 1000 <freep>
 9dc:	c515                	beqz	a0,a08 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9de:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9e0:	4798                	lw	a4,8(a5)
 9e2:	02977f63          	bgeu	a4,s1,a20 <malloc+0x70>
 9e6:	8a4e                	mv	s4,s3
 9e8:	0009871b          	sext.w	a4,s3
 9ec:	6685                	lui	a3,0x1
 9ee:	00d77363          	bgeu	a4,a3,9f4 <malloc+0x44>
 9f2:	6a05                	lui	s4,0x1
 9f4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9f8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9fc:	00000917          	auipc	s2,0x0
 a00:	60490913          	addi	s2,s2,1540 # 1000 <freep>
  if(p == (char*)-1)
 a04:	5afd                	li	s5,-1
 a06:	a88d                	j	a78 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 a08:	00000797          	auipc	a5,0x0
 a0c:	61878793          	addi	a5,a5,1560 # 1020 <base>
 a10:	00000717          	auipc	a4,0x0
 a14:	5ef73823          	sd	a5,1520(a4) # 1000 <freep>
 a18:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a1a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a1e:	b7e1                	j	9e6 <malloc+0x36>
      if(p->s.size == nunits)
 a20:	02e48b63          	beq	s1,a4,a56 <malloc+0xa6>
        p->s.size -= nunits;
 a24:	4137073b          	subw	a4,a4,s3
 a28:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a2a:	1702                	slli	a4,a4,0x20
 a2c:	9301                	srli	a4,a4,0x20
 a2e:	0712                	slli	a4,a4,0x4
 a30:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a32:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a36:	00000717          	auipc	a4,0x0
 a3a:	5ca73523          	sd	a0,1482(a4) # 1000 <freep>
      return (void*)(p + 1);
 a3e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a42:	70e2                	ld	ra,56(sp)
 a44:	7442                	ld	s0,48(sp)
 a46:	74a2                	ld	s1,40(sp)
 a48:	7902                	ld	s2,32(sp)
 a4a:	69e2                	ld	s3,24(sp)
 a4c:	6a42                	ld	s4,16(sp)
 a4e:	6aa2                	ld	s5,8(sp)
 a50:	6b02                	ld	s6,0(sp)
 a52:	6121                	addi	sp,sp,64
 a54:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a56:	6398                	ld	a4,0(a5)
 a58:	e118                	sd	a4,0(a0)
 a5a:	bff1                	j	a36 <malloc+0x86>
  hp->s.size = nu;
 a5c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a60:	0541                	addi	a0,a0,16
 a62:	00000097          	auipc	ra,0x0
 a66:	ec6080e7          	jalr	-314(ra) # 928 <free>
  return freep;
 a6a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a6e:	d971                	beqz	a0,a42 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a70:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a72:	4798                	lw	a4,8(a5)
 a74:	fa9776e3          	bgeu	a4,s1,a20 <malloc+0x70>
    if(p == freep)
 a78:	00093703          	ld	a4,0(s2)
 a7c:	853e                	mv	a0,a5
 a7e:	fef719e3          	bne	a4,a5,a70 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a82:	8552                	mv	a0,s4
 a84:	00000097          	auipc	ra,0x0
 a88:	b6e080e7          	jalr	-1170(ra) # 5f2 <sbrk>
  if(p == (char*)-1)
 a8c:	fd5518e3          	bne	a0,s5,a5c <malloc+0xac>
        return 0;
 a90:	4501                	li	a0,0
 a92:	bf45                	j	a42 <malloc+0x92>
