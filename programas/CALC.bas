# CALCULADORA - cuentas escritas como en el papel, con memoria e historial
REM CALCULADORA - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 0
R=0:M=0:GRA%=TRUE:T$=""
PROCpantalla
{bucle} REPEAT
PROCestado
VDU 28,0,14,63,14:CLS
PRINT "> ";
INPUT LINE "" T$
VDU 26
T$=FNmay(T$)
WHILE LEFT$(T$,1)=" ":T$=MID$(T$,2):ENDWHILE
IF T$<>"" THEN PROCorden(T$)
UNTIL FALSE
#
DEF PROCpantalla
CLS
PRINT TAB(0,1);STRING$(64,CHR$136);
PRINT TAB(0,12);STRING$(64,CHR$136);
PRINT TAB(0,13);"Funciones: SQR SIN COS TAN ASN ACS ATN LN LOG EXP ABS INT PI ^";
PRINT TAB(0,15);"R = último resultado   M = memoria   M+ M- MC   GRADOS RADIANES";
PROCnota("Escribí una cuenta y apretá Enter.  Ejemplos: (2+3)*4/7  SQR(2)")
PROCnota("Se puede usar coma o punto decimal.  BORRAR limpia la pantalla.")
ENDPROC
#
DEF PROCestado
PRINT TAB(0,0);"CALCULADORA";SPC(53);
PRINT TAB(24,0);"Ángulos en ";
IF GRA% THEN PRINT "grados"; ELSE PRINT "radianes";
PRINT TAB(46,0);LEFT$("M = "+STR$(M),18);
ENDPROC
#
DEF PROCorden(T$)
LOCAL X
IF T$="M+" THEN M=M+R:PROCnota("M+    memoria = "+STR$(M)):ENDPROC
IF T$="M-" THEN M=M-R:PROCnota("M-    memoria = "+STR$(M)):ENDPROC
IF T$="MC" THEN M=0:PROCnota("Memoria en cero"):ENDPROC
IF T$="GRADOS" THEN GRA%=TRUE:PROCnota("Ángulos en grados"):ENDPROC
IF T$="RADIANES" THEN GRA%=FALSE:PROCnota("Ángulos en radianes"):ENDPROC
IF T$="BORRAR" THEN PROCpantalla:ENDPROC
X=EVAL(FNtrad(T$))
R=X
PROCanota(T$,"= "+STR$(X))
ENDPROC
#
REM Escribe la cuenta a la izquierda y el resultado a la derecha
DEF PROCanota(T$,V$)
IF LEN(T$)+LEN(V$)>61 THEN PROCnota(LEFT$(T$,63)):T$=""
PROCnota(T$+STRING$(63-LEN(T$)-LEN(V$)," ")+V$)
ENDPROC
#
REM Agrega una línea al historial (ventana de las filas 2 a 11)
DEF PROCnota(L$)
VDU 28,0,11,63,2,31,0,9
PRINT
PRINT LEFT$(L$,63);
VDU 26
ENDPROC
#
REM Prepara la cuenta para el BASIC: coma decimal y ángulos en grados
DEF FNtrad(T$)
T$=FNcambia(T$,",",".")
IF NOT GRA% THEN =T$
T$=FNcambia(T$,"SIN(","FNsg(")
T$=FNcambia(T$,"COS(","FNcg(")
T$=FNcambia(T$,"TAN(","FNtg(")
T$=FNcambia(T$,"ASN(","FNasg(")
T$=FNcambia(T$,"ACS(","FNacg(")
=FNcambia(T$,"ATN(","FNatg(")
#
DEF FNcambia(T$,A$,B$)
LOCAL P%
P%=INSTR(T$,A$)
WHILE P%>0
T$=LEFT$(T$,P%-1)+B$+MID$(T$,P%+LEN(A$))
P%=INSTR(T$,A$,P%+LEN(B$))
ENDWHILE
=T$
#
DEF FNmay(T$)
LOCAL I%,C%,S$
IF T$="" THEN =""
FOR I%=1 TO LEN(T$)
C%=ASC(MID$(T$,I%,1))
IF C%>=97 AND C%<=122 THEN C%=C%-32
S$=S$+CHR$C%
NEXT
=S$
#
DEF FNsg(X)
=SIN(RAD(X))
DEF FNcg(X)
=COS(RAD(X))
DEF FNtg(X)
=TAN(RAD(X))
DEF FNasg(X)
=DEG(ASN(X))
DEF FNacg(X)
=DEG(ACS(X))
DEF FNatg(X)
=DEG(ATN(X))
#
DEF FNerror(E%)
IF E%=18 THEN ="División por cero"
IF E%=20 OR E%=24 THEN ="Número demasiado grande"
IF E%=21 THEN ="Raíz de un número negativo"
IF E%=22 THEN ="Logaritmo de cero o negativo"
IF E%=23 THEN ="Ángulo demasiado grande"
IF E%=26 THEN ="No conozco esa variable"
IF E%=29 THEN ="No conozco esa función"
IF E%=4 OR E%=5 OR E%=6 OR E%=9 OR E%=16 OR E%=27 OR E%=31 THEN ="Cuenta mal escrita"
="Error "+STR$(E%)
#
{error} IF ERR=17 THEN CHAIN "MENU"
VDU 26
PROCanota(T$,"¡"+FNerror(ERR)+"!")
GOTO {bucle}
