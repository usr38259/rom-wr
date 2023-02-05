<?php

$f = fopen ('COM7:', 'r+b');
if ($f === false) {
	echo "COM: open error.\n";
	exit (1);
}

$f_rom = fopen ('rom.bin', 'r+b');
if ($f_rom === false) {
	echo "rom.bin file open error.\n";
	fclose ($f);
	exit (1);
}

$c = fread ($f, 1);
if (ord ($c) != 0x55) {
	echo "Start byte error (\$", bin2hex ($c), " != \$55).\n";
	exit (1);
} else	echo "Start byte OK.\n";

check_mangling ();

fwrite ($f, chr (0x01) . chr (0x00) . chr (0x00) . chr (0xFF));		// DEBUG
$c = fread ($f, 1);
if (ord ($c) == 0x00)
	echo "DEBUG: write error.\n";

fwrite ($f, chr (0x02));	// shutdown
$c = fread ($f, 1);
if (ord ($c) != 0x00) {
	echo "Error: shutdown failed.\n";
	exit (1);
} else	echo "Shutdown OK.\n";

exit (1);

fwrite ($f, chr (0x03));	// set margin mode
$c = fread ($f, 1);
if (ord ($c) != 0x00) {
	echo "Error: set margin mode failed.\n";
	exit (1);
} else	echo "Set margin mode OK.\n";

for ($i = 0; $i < 65536; $i++) {
	echo 'Writing ', hexi16 ($i), ': ';
	$cw = fread ($f_rom, 1);
	if ($cw === false) {
		echo "ROM file read error.\n";
		break;
	}
	fwrite ($f, chr (0x01));
	$c = fread ($f, 1);
	if (ord ($c) != 0x00) {
		echo "\nError: Fail response (command \$01): ", bin2hex ($c), "\n";
		break;
	}
	fwrite ($f, chr ($i & 0xff));
	$c = fread ($f, 1);
	if (ord ($c) != 0x00) {
		echo "\nError: Fail response (low byte): ", bin2hex ($c), "\n";
		break;
	}
	fwrite ($f, chr (($i >> 8) & 0xff));
	fwrite ($f, $cw);
	$c = fread ($f, 1);
	if (ord ($c) != 0x00) {
		echo "\nError: Write fail: ", bin2hex ($c), "\n";
		$c = fread ($f, 1);
		echo "\tByte read: ", bin2hex ($c), "\n";
		$c = fread ($f, 1);
		echo "\tTries num: ", ord ($c), "\n";
		break;
	}
	$c = fread ($f, 2);
	echo 'ok (', bin2hex ($cw), ' == ', bin2hex ($c [0]), ')',
		ord ($c [1]) ? ' tries ' . ord ($c) : '', "\n";
}

fwrite ($f, chr (0x04));	// reset margin mode
$c = fread ($f, 1);
if (ord ($c) != 0x00) {
	echo "Error: reset margin mode failed.\n";
	exit (1);
} else	echo "Reset margin mode OK.\n";

fwrite ($f, chr (0x02));	// shutdown
$c = fread ($f, 1);
if (ord ($c) != 0x00) {
	echo "Error: shutdown failed.\n";
	exit (1);
} else	echo "Shutdown OK.\n";

fclose ($f);
fclose ($f_rom);

function hexi16 ($i) {
	return bin2hex (pack ('V', $i));
}

$al_bmap = array (6, 4, 2, 0, 7, 5, 3, 1);
$ah_bmap = array (3, 5, 6, 7, 4, 1, 0, 2);
$q_bmap = array (5, 3, 1, 0, 2, 4, 6, 7);
$dq_bmap = array (3, 2, 4, 1, 5, 0, 6, 7);

function check_mangling ()
{
	global $f, $al_bmap, $ah_bmap, $q_bmap, $dq_bmap;
	echo "Check mangling...\n";
	$fl = false;
	for ($i = 0; $i < 256; $i++) {
		fwrite ($f, chr (0x05) . chr ($i) . chr ($i) . chr ($i) . chr ($i));
		$s = fread ($f, 4);
		if (mangle_bmap ($i, $al_bmap) != mangle_bmap (ord ($s [0]), $al_bmap))
		{	echo "$i: al mangle failed.\n"; $fl = true;	}
		if (mangle_bmap ($i, $ah_bmap) != mangle_bmap (ord ($s [1]), $ah_bmap))
		{	echo "$i: ah mangle failed.\n"; $fl = true;	}
		if (mangle_bmap ($i, $q_bmap) != mangle_bmap (ord ($s [2]), $q_bmap))
		{	echo "$i: q mangle failed.\n"; $fl = true;	}
		if (mangle_bmap ($i, $dq_bmap) != mangle_bmap (ord ($s [3]), $dq_bmap))
		{	echo "$i: dq mangle failed.\n"; $fl = true;	}
	}
	if ($fl) exit (1);
}

function mangle_bmap ($c, $bmap)
{
	$m = 0;
	for ($i = 0; $i < 8; $i++)
		$m |= $c & (1 << $i) ? (1 << $bmap [$i]) : 0;
	return $m;
}

?>