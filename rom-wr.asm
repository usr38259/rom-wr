
.nolist
.include "m2560def.inc"
.list

.cseg

.macro	ITR
itr@0:	rjmp	reset
	nop
.endm

/* intr */
itr0:	rjmp	start
	nop
	ITR	1
	ITR	2
	ITR	3
	ITR	4
	ITR	5
	ITR	6
	ITR	7
	ITR	8
	ITR	9
	ITR	10
	ITR	11
	ITR	12
	ITR	13
	ITR	14
	ITR	15
	ITR	16
	ITR	17
	ITR	18
	ITR	19
	ITR	20
	ITR	21
	ITR	22
	ITR	23
	ITR	24
	ITR	25
	ITR	26
	ITR	27
	ITR	28
	ITR	29
	ITR	30
	ITR	31
	ITR	32
	ITR	33
	ITR	34
	ITR	35
	ITR	36
	ITR	37
	ITR	38
	ITR	39
	ITR	40
	ITR	41
	ITR	42
	ITR	43
	ITR	44
	ITR	45
	ITR	46
	ITR	47
	ITR	48
	ITR	49
	ITR	50
	ITR	51
	ITR	52
	ITR	53
	ITR	54
	ITR	55
	ITR	56
	ITR	57

reset:	jmp	LARGEBOOTSTART

start:	cli

	ldi	r16, high (RAMEND)
	out	SPH, r16
	ldi	r16, low  (RAMEND)
	out	SPL, r16

	rcall	setoff

	rcall	uart_txrx_init
rdy:	ldi	r16, $55
	rcall	uart_send
	clr	r16
	rcall	uart_send
	clr	r3

waitc:	rcall	uart_recv
	cpi	r16, $01
	breq	romwrc
	cpi	r16, $02
	brne	c02
	rjmp	shutdnc
c02:	cpi	r16, $03
	brne	c03
	rjmp	setwrmd
c03:	cpi	r16, $04
	brne	c04
	rjmp	rstwrmd
c04:	cpi	r16, $05
	brne	c05
	rjmp	check_mangle
c05:	cpi	r16, $06
	breq	rdy
	cpi	r16, $07
	brne	c07
	rjmp	romrd2
c07:	cpi	r16, $08
	brne	c08
	rjmp	romrd
c08:	cpi	r16, $09
	brne	c09
	rjmp	oehimp
c09:	cpi	r16, $0a
	brne	c0a
	rjmp	setoeh

c0a:	ldi	r16, $01
	rcall	uart_send
	rjmp	shutdn

romwrc:	sbrc	r3, 0
	rjmp	romwr
	ldi	r16, $02
	rcall	uart_send
	rjmp	shutdn
romwr:	clr	r16
	rcall	uart_send
	rcall	uart_recv
	mov	XL, r16
	rcall	uart_recv
	mov	XH, r16
	rcall	uart_recv
	mov	r1, r16
	mov	r16, XL
	rcall	uart_send
	mov	r16, XH
	rcall	uart_send
	mov	r16, r1
	rcall	uart_send
	rcall	uart_recv
	cp	r1, r16
	breq	wrs
	ldi	r16, $03
	rcall	uart_send
	rjmp	waitc

wrs:	rcall	mangle_all
	mov	r1, r16
	clr	r18
wrl:	mov	r16, r1
	rcall	rom_write
	rcall	rom_verify
	mov	r4, r16
	cp	r16, r1
	brne	wre
	clr	r16
	rjmp	wrr

.equ	rom_write_tries = 25

wre:	inc	r18
	cpi	r18, rom_write_tries
	brlo	wrl
	ldi	r16, $01
wrr:	rcall	uart_send
	mov	r16, r4
	mov	r4, r18
	rcall	demangle_q
	rcall	uart_send
	mov	r16, r4
	rcall	uart_send
	rjmp	waitc

romrd:	rcall	uart_recv
	mov	XL, r16
	rcall	uart_recv
	mov	XH, r16
	rcall	mangle_al
	rcall	mangle_ah
	rcall	rom_read
	rcall	demangle_q
	rcall	uart_send
	rjmp	waitc

romrd2:	rcall	uart_recv
	mov	XL, r16
	rcall	uart_recv
	mov	XH, r16
	rcall	mangle_al
	rcall	mangle_ah
	rcall	rom_read2
	rcall	demangle_q
	rcall	uart_send
	rjmp	waitc

setwrmd:
	ldi	r16, (1<<PORTG2)|(0<<PORTG1)|(1<<PORTG0)
	out	PORTG, r16
	ldi	r16, (1<<DDG2)|(1<<DDG1)|(1<<DDG0)
	out	DDRG, r16
	rcall	waitus1
	sbi	DDRG, DDG1
	clr	r0
	out	PORTC, r0
	sts	PORTL, r0
	ser	r16
	out	DDRC, r16
	sts	DDRL, r16
	ser	r16
	mov	r3, r16
	clr	r16
	rcall	uart_send
	rjmp	waitc

rstwrmd:
	rcall	setoff
	clr	r3
	clr	r16
	rcall	uart_send
	rjmp	waitc

shutdnc:
	clr	r16
	rcall	uart_send
shutdn:	rcall	shutdown
	rjmp	reset

shutdown:
	rcall	setoff
	rcall	uart_deinit
	ret

setoff:	clr	r0
	out	DDRA, r0
	out	DDRC, r0
	out	DDRG, r0
	sts	DDRL, r0
	out	PORTA, r0
	out	PORTC, r0
	out	PORTG, r0
	sts	PORTL, r0
	ret

.equ	rom_write_100us = 160		; ((100 us / 16 MHz) - 9) / 10
.equ	rom_write_TDV1 = 40		; 25 us (Data Valid from #CE)
.equ	rom_write_OEVPP_fall = 160	; 100 us (~92 us)
.equ	rom_VPP_pulse_rise = 40		; 25 us (Vpp Pulse Rise)

rom_write:
	out	PORTC, XL
	sts	PORTL, XH
	ser	r17
	out	PORTA, r16
	out	DDRA, r17
	sbi	PORTG, PORTG1
	ldi	r16, rom_VPP_pulse_rise
	rcall	waitus
	cbi	PORTG, PORTG0
	ldi	r16, rom_write_100us
	rcall	waitus
	sbi	PORTG, PORTG0
	rcall	waitus2
	clr	r0
	out	DDRA, r0
	out	PORTA, r0
	cbi	PORTG, PORTG1
	ldi	r16, rom_write_OEVPP_fall
	rcall	waitus
	ret

rom_verify:
	cbi	PORTG, PORTG2
	rcall	waitus1
	in	r16, PINA
	sbi	PORTG, PORTG2
	rcall	waitus1
	ret

waitus:			; r16 * 10 + 9 cycles
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	dec	r16
	brne	waitus
	ret

waitus1:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ret

waitus2:
	rcall	waitus1
	rcall	waitus1
	ret

rom_read:
	clr	r16
	out	PORTA, r16
	cbi	PORTG, PORTG0
	out	PORTC, XL
	sts	PORTL, XH
	cbi	PORTG, PORTG2
	nop
	in	r16, PINA
	sbi	PORTG, PORTG2
	sbi	PORTG, PORTG0
	ret

rom_read2:
	clr	r16
	out	PORTA, r16
	cbi	PORTG, PORTG0
	out	PORTC, XL
	sts	PORTL, XH
	cbi	PORTG, PORTG2
	nop
	nop
	nop
	in	r16, PINA
	sbi	PORTG, PORTG2
	sbi	PORTG, PORTG0
	ret

.equ	uart_ubrrl =	16	; XTAL 16 MHz U2X=1 115200 kbps
;.equ	uart_ubrrl =	103	; XTAL 16 MHz U2X=0 9600 kbps
.equ	uart_tx_timeout = 300	; 8 [presc. div, U2X=1] * 17 [uart_ubrr + 1] * 9 [baud bits] / 5 [loop tcks]

uart_trans_init:
	clr	r16
	sts	UBRR0H, r16
	ldi	r16, uart_ubrrl
	sts	UBRR0L, r16
	ldi	r16, (1<<U2X0)
	sts	UCSR0A, r16
	ldi	r16, (1<<TXEN0)
	sts	UCSR0B, r16
	ldi	r16, (1<<UCSZ01)|(1<<UCSZ00)
	sts	UCSR0C, r16
	ret

uart_send:
wtdr:	lds	r17, UCSR0A
	sbrs	r17, UDRE0
	rjmp	wtdr
	sbr	r17, TXC0
	sts	UCSR0A, r17
	sts	UDR0, r16
	ret

uart_wait_send:
	ldi	XH, high (uart_tx_timeout)
	ldi	XL, low (uart_tx_timeout)
wttr:	sbiw	X, 1
	breq	wtrt
	lds	r17, UCSR0A
	sbrs	r17, TXC0
	rjmp	wttr
wtrt:	ret

uart_deinit:
	clr	r16
	sts	UCSR0A, r16
	sts	UCSR0B, r16
	ldi	r16, (1<<UCSZ01)|(1<<UCSZ00)
	sts	UCSR0C, r16
	ret

uart_recv_init:
	clr	r16
	sts	UBRR0H, r16
	ldi	r16, uart_ubrrl
	sts	UBRR0L, r16
	ldi	r16, (1<<U2X0)
	sts	UCSR0A, r16
	ldi	r16, (1<<RXEN0)
	sts	UCSR0B, r16
	ldi	r16, (1<<UCSZ01)|(1<<UCSZ00)
	sts	UCSR0C, r16
	ret

uart_recv:
wtrc:	lds	r16, UCSR0A
	sbrs	r16, RXC0
	rjmp	wtrc
	lds	r16, UDR0
	ret

uart_txrx_init:
	clr	r16
	sts	UBRR0H, r16
	ldi	r16, uart_ubrrl
	sts	UBRR0L, r16
	ldi	r16, (1<<U2X0)
	sts	UCSR0A, r16
	ldi	r16, (1<<RXEN0)|(1<<TXEN0)
	sts	UCSR0B, r16
	ldi	r16, (1<<UCSZ01)|(1<<UCSZ00)
	sts	UCSR0C, r16
	ret

mangle_all:
	mov	r2, r16
	rcall	mangle_al
	rcall	mangle_ah
	mov	r16, r2
	rcall	mangle_q
	ret

mangle_al:
	mov	r16, XL
	ldi	ZL, low (almngl<<1)
	ldi	ZH, high (almngl<<1)
	rcall	mangle
	mov	XL, r16
	ret

mangle_ah:
	mov	r16, XH
	ldi	ZL, low (ahmngl<<1)
	ldi	ZH, high (ahmngl<<1)
	rcall	mangle
	mov	XH, r16
	ret

mangle_q:
	ldi	ZL, low (qmngl<<1)
	ldi	ZH, high (qmngl<<1)
	rcall	mangle
	ret

demangle_q:
	ldi	ZL, low (qdmgl<<1)
	ldi	ZH, high (qdmgl<<1)
	rcall	mangle
	ret

mangle:
	mov	r0, r16
	clr	r16
mngnx:	lpm	r1, Z+		; next table item
	tst	r0
	breq	mngrt
	lsr	r0
	brcc	mnnn		; next nibble
	mov	r17, r1
	andi	r17, $0f
	ldi	r18, 1
mnsl1:	tst	r17
	breq	mnsl1e
	dec	r17
	lsl	r18		; shift loop
	rjmp	mnsl1
mnsl1e:	eor	r16, r18
mnnn:	tst	r0
	breq	mngrt
	lsr	r0
	brcc	mngnx
	lsr	r1
	lsr	r1
	lsr	r1
	lsr	r1
	ldi	r18, 1
mnsl2:	tst	r1
	breq	mnsl2e
	dec	r1
	lsl	r18
	rjmp	mnsl2
mnsl2e:	eor	r16, r18
	rjmp	mngnx
mngrt:	ret

almngl:
.db	$46, $02, $57, $13
ahmngl:
.db	$53, $76, $14, $20
qmngl:
.db	$35, $01, $42, $76
qdmgl:
.db	$23, $14, $05, $76

check_mangle:
	rcall	uart_recv
	mov	XL, r16
	rcall	uart_send
	rcall	uart_recv
	mov	XH, r16
	rcall	uart_send
	rcall	uart_recv
	mov	r19, r16
	rcall	uart_send
	rcall	uart_recv
	mov	r20, r16
	rcall	uart_send
	mov	r16, r19
	rcall	mangle_all
	mov	r19, r16
	mov	r16, XL
	rcall	uart_send
	mov	r16, XH
	rcall	uart_send
	mov	r16, r19
	rcall	uart_send
	mov	r16, r20
	rcall	demangle_q
	rcall	uart_send
	rjmp	waitc

oehimp:	sbi	PORTG, PORTG0
	sbi	DDRG, DDG0
	sbi	PORTG, PORTG2
	sbi	DDRG, DDG2
	sbi	DDRG, DDG1
	rcall	waitus1
oehil:	sbi	PORTG, PORTG1
	ldi	r16, rom_write_100us
	rcall	waitus
	cbi	PORTG, PORTG1
	ldi	r16, rom_write_OEVPP_fall
	rcall	waitus
	rjmp	oehil

setoeh:	sbi	PORTG, PORTG0
	sbi	DDRG, DDG0
	sbi	PORTG, PORTG2
	sbi	DDRG, DDG2
	rcall	waitus1
	sbi	PORTG, PORTG1
	sbi	DDRG, DDG1
	rjmp	waitc
