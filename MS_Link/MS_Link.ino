/*
 * MS-LINK 4 - adaptador USB <-> puerto paralelo de la MailStation
 * para Arduino Uno (o Nano). Altaris Software, 2026.
 *
 * Sirve para tres cosas:
 *   - mandar un programa al "Loader" del firmware original (comando S);
 *   - instalar ALTARIS 80 y hacer el respaldo de la memoria (W y R);
 *   - pasar archivos con *RECIBIR y *ENVIAR de ALTARIS (W y R).
 * La PC hace todo el trabajo (pc/altaris_pc.py); el Arduino solo pasa bytes
 * con el protocolo de 3 bits por vez de la MailStation.
 *
 * Basado en teensy-loader de joshua stein:
 * Copyright (c) 2020 joshua stein <jcs@jcs.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * CONEXIONES (pin del Arduino -> pin del conector DB25 de la MailStation)
 *
 *   D2  <- pin 2      D7  -> pin 10
 *   D3  <- pin 3      D8  -> pin 11
 *   D4  <- pin 4      D9  -> pin 12
 *   D5  <- pin 5      D10 -> pin 13
 *   D6  <- pin 6      D11 -> pin 15
 *   GND -- pin 25
 *
 * PROTOCOLO CON LA PC (115200 baudios)
 *
 *   'P'              -> "MSLINK OK 4\n"
 *   'S' lo hi        -> manda el largo al Loader y responde 'K'; despues
 *                       recibe los datos en bloques de hasta 32 bytes y
 *                       responde 'K' por cada bloque
 *   'W' n datos      -> manda n bytes (1 a 32) a la MailStation; 'K' o 'E'
 *   'R' n            -> recibe n bytes (1 a 32) de la MailStation;
 *                       'K' y los n bytes, 'T' si no llego nada (se puede
 *                       volver a pedir) o 'E' si se corto a la mitad
 *   'Q' v            -> prueba de cables: pone v (5 bits) en las salidas
 *                       D11, D10, D9, D7, D8 y responde 'K' y lo que lee en
 *                       D2-D6 (5 bits). Con CABLES.BIN en la MailStation
 *                       tiene que volver lo mismo.
 *   Si la PC deja de mandar datos a mitad de un comando responde 'T'.
 */

/* entradas: lineas de datos D0-D4 de la MailStation */
const int pIn0 = 2;	/* DB25 pin 2 */
const int pIn1 = 3;	/* DB25 pin 3 */
const int pIn2 = 4;	/* DB25 pin 4 */
const int pIn3 = 5;	/* DB25 pin 5 */
const int pIn4 = 6;	/* DB25 pin 6 */

/* salidas: lineas de estado de la MailStation */
const int pOut3 = 7;	/* DB25 pin 10 (Ack) */
const int pOut4 = 8;	/* DB25 pin 11 (Busy) */
const int pOut2 = 9;	/* DB25 pin 12 (Paper Out) */
const int pOut1 = 10;	/* DB25 pin 13 (Select) */
const int pOut0 = 11;	/* DB25 pin 15 (Error) */

const int pLED = 13;

#define BSYIN		0x40	/* en readstatus() */
#define STBIN		0x80
#define BSYOUT		0x08	/* en writedata() */
#define STBOUT		0x10
#define TRIBMASK	0x07

#define TIMEOUT_MS	3000UL	/* espera maxima a la MailStation */
#define BLOQUE		32	/* el buffer serie del Uno/Nano es de 64 */

int
readstatus(void)
{
	return (digitalRead(pIn4) == HIGH ? 0x80 : 0) |
	    (digitalRead(pIn3) == HIGH ? 0x40 : 0) |
	    (digitalRead(pIn2) == HIGH ? 0x20 : 0) |
	    (digitalRead(pIn1) == HIGH ? 0x10 : 0) |
	    (digitalRead(pIn0) == HIGH ? 0x08 : 0);
}

void
writedata(unsigned char b)
{
	digitalWrite(pOut0, (b & 0x01) ? HIGH : LOW);
	digitalWrite(pOut1, (b & 0x02) ? HIGH : LOW);
	digitalWrite(pOut2, (b & 0x04) ? HIGH : LOW);
	digitalWrite(pOut3, (b & 0x08) ? HIGH : LOW);
	digitalWrite(pOut4, (b & 0x10) ? HIGH : LOW);
}

/* espera a que el bit "mask" del estado quede en "valor"; false si se vence */
bool
esperar(int mask, bool valor)
{
	unsigned long t0 = millis();

	while (((readstatus() & mask) != 0) != valor) {
		if (millis() - t0 > TIMEOUT_MS)
			return false;
	}
	return true;
}

/* manda 3 bits a la MailStation */
bool
sendtribble(unsigned char b)
{
	bool ok;

	/*
	 * Busy (pin 10) queda arriba todo el tiempo: la MailStation lo mira
	 * solo para saber cuando puede mandar. writedata() cambia los pines de
	 * a uno (pin 10 antes que el strobe); si busy bajara aunque sea un
	 * instante despues del strobe, la MailStation, que contesta enseguida,
	 * mandaria la respuesta cuando el Arduino todavia no escucha.
	 */
	writedata(BSYOUT);			/* busy arriba */

	ok = esperar(BSYIN, false);		/* la MailStation baja busy */
	if (ok) {
		writedata((b & TRIBMASK) | BSYOUT);	/* poner los 3 bits */
		writedata((b & TRIBMASK) | BSYOUT | STBOUT); /* strobe */
		ok = esperar(BSYIN, true);	/* la MailStation confirma */
	}

	writedata(BSYOUT);			/* bajar strobe, busy sigue arriba */
	return ok;
}

/* un byte son 3 envios: bits 0-2, 3-5 y 6-7 */
bool
sendbyte(unsigned char b)
{
	digitalWrite(pLED, HIGH);
	bool ok = sendtribble(b) && sendtribble(b >> 3) && sendtribble(b >> 6);
	digitalWrite(pLED, LOW);
	return ok;
}

/*
 * recibe 3 bits de la MailStation: -1 si no llego nada, -2 si la
 * MailStation no termino el intercambio
 */
int
recvtribble(void)
{
	int v;

	writedata(0);				/* listos: bajar busy */
	if (!esperar(STBIN, true)) {		/* esperar el strobe */
		writedata(BSYOUT);
		return -1;
	}
	v = (readstatus() >> 3) & TRIBMASK;	/* los 3 bits */
	writedata(BSYOUT);			/* confirmar */
	if (!esperar(STBIN, false))		/* la MailStation baja strobe */
		return -2;
	return v;
}

/* recibe un byte: -1 si no llego nada, -2 si se corto a la mitad */
int
recvbyte(void)
{
	int a, b, c;

	a = recvtribble();
	if (a < 0)
		return a;
	digitalWrite(pLED, HIGH);
	b = recvtribble();
	c = (b < 0) ? -2 : recvtribble();
	digitalWrite(pLED, LOW);
	if (b < 0 || c < 0)
		return -2;
	return a | (b << 3) | ((c & 3) << 6);
}

void
setup(void)
{
	Serial.begin(115200);
	Serial.setTimeout(2000);

	pinMode(pOut0, OUTPUT);
	pinMode(pOut1, OUTPUT);
	pinMode(pOut2, OUTPUT);
	pinMode(pOut3, OUTPUT);
	pinMode(pOut4, OUTPUT);

	pinMode(pIn0, INPUT);
	pinMode(pIn1, INPUT);
	pinMode(pIn2, INPUT);
	pinMode(pIn3, INPUT);
	pinMode(pIn4, INPUT);

	pinMode(pLED, OUTPUT);

	writedata(BSYOUT);

	Serial.print(F("MSLINK OK 4\n"));
}

void
enviar_programa(void)
{
	unsigned char cab[2], buf[BLOQUE];
	unsigned int largo, n, i;

	/* largo del programa, el Loader lo espera primero */
	if (Serial.readBytes(cab, 2) != 2) {
		Serial.write('T');
		return;
	}
	if (!sendbyte(cab[0]) || !sendbyte(cab[1])) {
		Serial.write('E');
		return;
	}
	Serial.write('K');

	largo = cab[0] | (cab[1] << 8);
	while (largo > 0) {
		n = (largo > BLOQUE) ? BLOQUE : largo;
		if (Serial.readBytes(buf, n) != n) {
			Serial.write('T');
			return;
		}
		for (i = 0; i < n; i++) {
			if (!sendbyte(buf[i])) {
				Serial.write('E');
				return;
			}
		}
		largo -= n;
		Serial.write('K');
	}
}

/* 'W': n bytes de la PC a la MailStation */
void
escribir(void)
{
	unsigned char buf[BLOQUE];
	int n, i;

	if (Serial.readBytes(buf, 1) != 1) {
		Serial.write('T');
		return;
	}
	n = buf[0];
	if (n < 1 || n > BLOQUE || Serial.readBytes(buf, n) != (size_t)n) {
		Serial.write('T');
		return;
	}
	for (i = 0; i < n; i++) {
		if (!sendbyte(buf[i])) {
			Serial.write('E');
			return;
		}
	}
	Serial.write('K');
}

/* 'R': n bytes de la MailStation a la PC */
void
leer(void)
{
	unsigned char buf[BLOQUE];
	int n, i, c;

	if (Serial.readBytes(buf, 1) != 1) {
		Serial.write('T');
		return;
	}
	n = buf[0];
	if (n < 1 || n > BLOQUE) {
		Serial.write('T');
		return;
	}
	for (i = 0; i < n; i++) {
		c = recvbyte();
		if (c == -1 && i == 0) {
			Serial.write('T');	/* todavia no llego nada */
			return;
		}
		if (c < 0) {
			Serial.write('E');
			return;
		}
		buf[i] = c;
	}
	Serial.write('K');
	Serial.write(buf, n);
}

/* 'Q': prueba de cables */
void
cables(void)
{
	unsigned char v;

	if (Serial.readBytes(&v, 1) != 1) {
		Serial.write('T');
		return;
	}
	writedata(v & 0x1F);
	delay(20);			/* la MailStation copia y muestra */
	Serial.write('K');
	Serial.write((unsigned char)(readstatus() >> 3));
}

void
loop(void)
{
	int c;

	if (!Serial.available())
		return;

	c = Serial.read();
	if (c == 'P')
		Serial.print(F("MSLINK OK 4\n"));
	else if (c == 'S')
		enviar_programa();
	else if (c == 'W')
		escribir();
	else if (c == 'R')
		leer();
	else if (c == 'Q')
		cables();
}
