
#include <stdio.h>
#include <windows.h>

CHAR szCommName [] = "\\\\.\\COM7";
BYTE Buff [16];

HANDLE hComm = INVALID_HANDLE_VALUE;
BOOL usend (int n);
BOOL urecv (int n);

BYTE mangle (BYTE n, const BYTE bmap[]);
extern const BYTE albmap[], ahbmap[], qbmap[], dqbmap[];

void check_mangle (void);
int prog_byte (WORD addr, BYTE byte);

BYTE rom [65536];

int __cdecl main ()
{
	COMMCONFIG ComCfg;
	COMMPROP CommProp;
	DCB Dcb;
	COMMTIMEOUTS CommTimeouts;
	DWORD dwSize, dw;
	BOOL bRes;
	int i;
	FILE *f_rom;
	size_t n;

//	mangle (0x55, albmap);		// DEBUG
//	return 0;
__try {
	hComm = CreateFile (szCommName, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING,
		0, NULL);
	if (hComm == INVALID_HANDLE_VALUE) {
		puts ("COM: open error.");
		return 1;
	}

	f_rom = fopen ("rom.bin", "rb");
	if (f_rom == NULL) {
		puts ("ROM file open error.");
		return 1;
	}
	n = fread (rom, 16384, 1, f_rom);
	if (n != 1) {
		puts ("ROM file read error.");
		fclose (f_rom);
		return 1;
	}
	fclose (f_rom);
	f_rom = fopen ("rom1.bin", "rb");
	if (f_rom == NULL) {
		puts ("ROM file open error.");
		return 1;
	}
	n = fread (&rom[16384], 16384, 1, f_rom);
	if (n != 1) {
		puts ("ROM1 file read error.");
		fclose (f_rom);
		return 1;
	}
	fclose (f_rom);
/*	dwSize = sizeof (ComCfg);
	bRes = GetCommConfig (hComm, &ComCfg, &dwSize);
	bRes = GetCommMask (hComm, &dw);
	bRes = GetCommModemStatus (hComm, &dw);
	bRes = GetCommProperties (hComm, &CommProp);
	bRes = GetCommState (hComm, &Dcb);
	bRes = GetCommTimeouts (hComm, &CommTimeouts);
*/
/*	Buff [0] = 0x02;
	bRes = send (1);
	bRes = recv (2);
*/
	urecv (2);
	if (Buff [0] != 0x55 || Buff [1] != 0x00) {
		printf ("Start byte error (%02x%02x).\n", Buff [0], Buff [1]);
		return 1;
	} else
		puts ("Start byte OK.");
/*
	puts ("Setting #OE VPP High.");
	Buff [0] = 0x0a;
	usend (1);

	puts ("Setting #OE-2 High.");
	Buff [0] = 0x0b;
	usend (1);
	return 0;
*/
/*	puts ("Setting #OE imp.");
	Buff [0] = 0x0c;
	usend (1);
	return 0;
*/
	check_mangle ();
	memset (rom, 0x55, 65536);
/*
	Buff [0] = 0x09;
	usend (1);

	Sleep (30000);

	Buff [0] = 0x0a;
	usend (1);
	return 0;
*/
	Buff [0] = 0x03;
	usend (1);
	urecv (1);
	if (Buff [0] == 0x00)
		puts ("Set write mode OK.");

	for (i = 0; i < 32768; i++) {
		Buff [0] = 0x07;
		Buff [1] = LOBYTE (i);
		Buff [2] = HIBYTE (i);
		usend (3);
		urecv (1);
		printf ("%04x: read %02x\n", i, Buff [0]);
		rom [i] = Buff [0];
	}

//	prog_byte (0x0000, 0xF3);
//	prog_byte (0x0001, 0xAF);

/*
	for (i = 1; i < 32768; i++) {
		if (prog_byte ((WORD)i, rom [i]) != 0)
			return 1;
	} */
/*
	Buff [0] = 0x01;
	usend (1);
	urecv (1);
	if (Buff [0] != 0x00) {
		printf ("Write reject (%02x).\n", Buff [0]);
		return 1;
	}
	Buff [0] = 0;
	Buff [1] = 0;
	Buff [2] = 0xF3;
	usend (3);
	urecv (3);
	if (Buff [0] != 0 || Buff [1] != 0 || Buff [2] != 0xF3) {
		printf ("Write echo error (%02x %02x %02x).\n",
			Buff [0], Buff [1], Buff [2]);
		return 1;
	}
	Buff [0] = 0xF3;
	usend (1);
	urecv (1);
	if (Buff [0] == 0x00 || Buff [0] == 0x01) {
		BYTE b = Buff [0];
		urecv (2);
		printf ("%04x: Write response: %02x %02x %02x\n",
			0, b, Buff [0], Buff [1]);
		if (b != 0x00) return 1;
	} else {
		printf ("Write response: %02x\n", Buff [0]);
		return 1;
	}
*/
/*
	for (i = 0; i < 16; i++) {
		Buff [0] = 0x07;
		Buff [1] = LOBYTE (i);
		Buff [2] = HIBYTE (i);
		usend (3);
		urecv (1);
		printf ("%04x: read %02x\n", i, Buff [0]);
		rom [i] = Buff [0];
	}
*/
/*
	for (i = 1; i < 32768; i++) {
	Buff [0] = 0x01;
	usend (1);
	urecv (1);
	if (Buff [0] != 0x00) {
		printf ("Write reject (%02x).\n", Buff [0]);
		return 1;
	}
	Buff [0] = LOBYTE (i);
	Buff [1] = HIBYTE (i);
	Buff [2] = rom [i];
	usend (3);
	urecv (3);
	if (Buff [0] != LOBYTE (i) || Buff [1] != HIBYTE (i) || Buff [2] != rom [i]) {
		printf ("Write echo error (%02x %02x %02x).\n",
			Buff [0], Buff [1], Buff [2]);
		return 1;
	}
	Buff [0] = rom [i];
	usend (1);
	urecv (1);
	if (Buff [0] == 0x00 || Buff [0] == 0x01) {
		BYTE b = Buff [0];
		urecv (2);
		printf ("%04x: Write response: %02x %02x %02x\n",
			i, b, Buff [0], Buff [1]);
		if (b != 0x00) return 1;
	} else {
		printf ("Write response: %02x\n", Buff [0]);
		return 1;
	}
	} */

	Buff [0] = 0x04;
	usend (1);
	urecv (1);
	if (Buff [0] == 0x00)
		puts ("Reset write mode OK.");

	Buff [0] = 0x02;
	usend (1);
	urecv (1);
	if (Buff [0] == 0x00)
		puts ("Shutdown OK.");

	f_rom = fopen ("romwr.bin", "wb");
	fwrite (rom, 65536, 1, f_rom);
	fclose (f_rom);
} __finally {
	if (hComm != INVALID_HANDLE_VALUE) CloseHandle (hComm);
}
	return 0;
}

BOOL usend (int n)
{
	DWORD dw;
	BOOL bRes;
	bRes = WriteFile (hComm, Buff, n, &dw, NULL);
	if (!bRes)
		printf ("COM: send error (%d bytes).\n", n);
	return bRes;
}

BOOL urecv (int n)
{
	DWORD dw;
	BOOL bRes;
	bRes = ReadFile (hComm, Buff, n, &dw, NULL);
	if (!bRes)
		printf ("COM: receive error (%d bytes).\n", n);
	return bRes;
}

int prog_byte (WORD addr, BYTE byte)
{
	int i;

	Buff [0] = 0x01;
	usend (1);
	urecv (1);
	if (Buff [0] != 0x00) {
		printf ("Write reject (%02x).\n", Buff [0]);
		return -1;
	}
	Buff [0] = LOBYTE (addr);
	Buff [1] = HIBYTE (addr);
	Buff [2] = byte;
	usend (3);
	urecv (3);
	if (Buff [0] != LOBYTE (addr) || Buff [1] != HIBYTE (addr) || Buff [2] != byte) {
		printf ("Write echo error (%02x %02x %02x).\n",
			Buff [0], Buff [1], Buff [2]);
		return -1;
	}
	Buff [0] = byte;
	usend (1);
	urecv (1);
	if (Buff [0] == 0x00 || Buff [0] == 0x01) {
		BYTE b = Buff [0];
		urecv (2);
		printf ("%04x: Write response: %02x %02x %02x\n",
			addr, b, Buff [0], Buff [1]);
/*		if (Buff [2] != byte) {
			b = 1;
			printf ("%04x RD ROM:", addr);
			for (i = 0; i < 3; i++) {
				Buff [0] = 0x07;
				Buff [1] = LOBYTE (addr);
				Buff [2] = HIBYTE (addr);
				usend (3);
				urecv (1);
				printf (" %02x", Buff [0]);
				if (Buff [0] == byte) {
					b = 0; break;
				}
				puts ("");
			}
		} */
		return b;
	} else {
		printf ("Write response: %02x\n", Buff [0]);
		return Buff [0];
	}
}

const BYTE albmap [] = { 6, 4, 2, 0, 7, 5, 3, 1 };
const BYTE ahbmap [] = { 3, 5, 6, 7, 4, 1, 0, 2 };
const BYTE qbmap  [] = { 5, 3, 1, 0, 2, 4, 6, 7 };
const BYTE dqbmap [] = { 3, 2, 4, 1, 5, 0, 6, 7 };

BYTE mangle (BYTE n, const BYTE bmap[])
{
		int i, r = 0;
		for (i = 0; i < 8; i++)
			r |= n & (1 << i) ? 1 << bmap [i] : 0;
		return r;
}

void check_mangle (void)
{
	int i, fl = 0;
	puts ("Mangling check...");
	for (i = 0; i < 256; i++) {
		Buff [0] = 0x05; Buff [1] = i; Buff [2] = i;
		Buff [3] = i; Buff [4] = i;
		usend (5);
		urecv (8);
/*		printf ("%02x: %02x%02x%02x%02x ", i, Buff [0], Buff [1],
			Buff [2], Buff [3]); */
		if (Buff [0] != i || Buff [1] != i || Buff [2] != i ||
			Buff [3] != i) { printf ("echo error "); fl = 1; }
		Buff [0] = mangle ((BYTE)i, albmap);
		Buff [1] = mangle ((BYTE)i, ahbmap);
		Buff [2] = mangle ((BYTE)i,  qbmap);
		Buff [3] = mangle ((BYTE)i, dqbmap);
/*		printf ("%02x%02x%02x%02x %02x%02x%02x%02x\n", Buff [4], Buff [5],
			Buff [6], Buff [7], Buff [0], Buff [1], Buff [2], Buff [3]); */
		if (memcmp (&Buff [0], &Buff [4], 4) != 0)
		{	printf ("%d: mangle failed.\n", i); fl = 1; }
	}
	if (fl) exit (1);
}
