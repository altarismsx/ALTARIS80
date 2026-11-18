# AGENDA - nombres, teléfonos, direcciones y cumpleaños
REM AGENDA - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 0
*ESC OFF
MR%=70:VI%=13
DIM NO$(MR%),TE$(MR%),DI$(MR%),CO$(MR%),CU$(MR%),NT$(MR%),KY$(MR%+1),TT%(12),FA%(MR%)
DIM LB$(6),LG%(6)
REM Se reserva el lugar de cada dato (el BASIC no recupera memoria de cadenas)
FOR I%=0 TO MR%
NO$(I%)=STRING$(30," "):TE$(I%)=STRING$(20," "):DI$(I%)=STRING$(32," ")
CO$(I%)=STRING$(32," "):CU$(I%)=STRING$(5," "):NT$(I%)=STRING$(32," ")
KY$(I%)=STRING$(30," ")
NO$(I%)="":TE$(I%)="":DI$(I%)="":CO$(I%)="":CU$(I%)="":NT$(I%)="":KY$(I%)=""
NEXT
T$=STRING$(255," "):N$=STRING$(63," "):M$=STRING$(63," "):B$=STRING$(40," ")
S$=STRING$(63," "):V$=STRING$(63," "):B$="":M$="":V$=""
RESTORE {datos}
FOR I%=1 TO 6:READ LB$(I%),LG%(I%):NEXT
FOR I%=1 TO 12:READ TT%(I%):NEXT
MAY%=?&FA96:?&FA96=0
VDU 23,1,0;0;0;0;
NR%=0:SE%=1:ARR%=1
PROCcargar
PROClista
PROCavisos
{bucle} REPEAT
PROCmarca(TRUE)
K%=GET
PROCmarca(FALSE)
PROCtecla(K%)
UNTIL FALSE
#
DEF PROCtecla(K%)
IF K%=139 AND SE%>1 THEN SE%=SE%-1:PROCver
IF K%=138 AND SE%<NR% THEN SE%=SE%+1:PROCver
IF K%=140 THEN SE%=SE%-VI%:IF SE%<1 THEN SE%=1
IF K%=141 THEN SE%=SE%+VI%:IF SE%>NR% THEN SE%=NR%
IF K%=140 OR K%=141 THEN PROCver
IF K%=13 AND NR%>0 THEN PROCficha(SE%)
IF K%=129 THEN PROCnueva
IF K%=130 AND NR%>0 THEN PROCeditar(SE%):PROClista
IF K%=131 AND NR%>0 THEN PROCborrar(SE%)
IF K%=132 THEN PROCbuscar
IF K%=133 THEN PROCcumples
IF K%=27 OR K%=128 THEN PROCsalir
IF (K%>=65 AND K%<=90) OR (K%>=97 AND K%<=122) THEN PROCletra(K%)
ENDPROC
#
REM ---------------- Pantalla de la lista ----------------
DEF PROClista
CLS:FIL%=0
PRINT TAB(0,0);"AGENDA";TAB(40,0);RIGHT$("    "+STR$(NR%),4);" persona";
IF NR%<>1 THEN PRINT "s";
PRINT TAB(0,1);" Nombre";TAB(33,1);"Teléfono";TAB(54,1);"Cumple";
PRINT TAB(0,15);"F1 Nueva F2 Cambiar F3 Borrar F4 Buscar F5 Cumpleaños  Volver";
IF NR%=0 THEN PRINT TAB(4,6);"La agenda está vacía.":PRINT TAB(4,8);"Apretá F1 para anotar a la primera persona.";:ENDPROC
PROCver
ENDPROC
#
REM Acomoda la parte visible para que se vea la persona elegida
DEF PROCver
LOCAL I%
IF NR%=0 THEN ENDPROC
IF SE%<ARR% THEN ARR%=SE%:PROCfilas:ENDPROC
IF SE%>=ARR%+VI% THEN ARR%=SE%-VI%+1:PROCfilas:ENDPROC
IF FIL%=0 THEN PROCfilas
ENDPROC
#
DEF PROCfilas
LOCAL I%
FOR I%=ARR% TO ARR%+VI%-1:PROCfila(I%,FALSE):NEXT
FIL%=1
ENDPROC
#
DEF PROCfila(I%,M%)
PRINT TAB(0,2+I%-ARR%);
IF I%>NR% THEN PRINT SPC(63);:ENDPROC
IF M% THEN COLOUR 129:COLOUR 0
PRINT " ";NO$(I%);SPC(32-LEN(NO$(I%)));LEFT$(TE$(I%),20);SPC(21-LEN(LEFT$(TE$(I%),20)));CU$(I%);SPC(9-LEN(CU$(I%)));
COLOUR 128:COLOUR 1
ENDPROC
#
DEF PROCmarca(M%)
IF NR%>0 THEN PROCfila(SE%,M%)
ENDPROC
#
REM Una letra salta a la primera persona que empieza con ella
DEF PROCletra(K%)
LOCAL I%,C$
IF K%>=97 THEN K%=K%-32
C$=CHR$K%:I%=1
WHILE I%<=NR% AND LEFT$(KY$(I%),1)<C$:I%=I%+1:ENDWHILE
IF I%>NR% THEN I%=NR%
IF I%>0 THEN SE%=I%:PROCver
ENDPROC
#
REM ---------------- Ficha de una persona ----------------
DEF PROCficha(I%)
LOCAL K%
REPEAT
CLS
PRINT TAB(0,0);"FICHA ";I%;" de ";NR%
PRINT TAB(0,1);STRING$(64,CHR$136);
PRINT TAB(2,3);"Nombre:     ";NO$(I%)
PRINT TAB(2,5);"Teléfono:   ";TE$(I%)
PRINT TAB(2,7);"Dirección:  ";DI$(I%)
PRINT TAB(2,9);"Correo:     ";CO$(I%)
PRINT TAB(2,11);"Cumpleaños: ";CU$(I%)
PRINT TAB(2,13);"Nota:       ";NT$(I%)
PRINT TAB(0,15);"Flechas: otra ficha   F2 Cambiar   F3 Borrar   Volver: lista";
K%=GET
IF K%=139 AND I%>1 THEN I%=I%-1
IF K%=138 AND I%<NR% THEN I%=I%+1
IF K%=130 THEN PROCeditar(I%):I%=SE%
IF K%=131 THEN PROCborrar(I%):K%=27
UNTIL K%=27 OR K%=128 OR NR%=0
SE%=I%:IF SE%>NR% THEN SE%=NR%
FIL%=0:PROClista
ENDPROC
#
REM ---------------- Altas, cambios y bajas ----------------
DEF PROCnueva
IF NR%>=MR% THEN PROCaviso("La agenda está llena ("+STR$(MR%)+" personas)"):ENDPROC
NR%=NR%+1
NO$(NR%)="":TE$(NR%)="":DI$(NR%)="":CO$(NR%)="":CU$(NR%)="":NT$(NR%)=""
PROCeditar(NR%)
IF NO$(SE%)="" THEN PROCquitar(SE%):PROCgrabar
PROClista
ENDPROC
#
REM Pide los datos uno por uno. Enter = dejar igual, un guión = borrar el dato
DEF PROCeditar(I%)
LOCAL F%
CLS
PRINT TAB(0,0);"DATOS DE LA PERSONA"
PRINT TAB(0,1);"Enter deja el dato como está;  un guión (-) lo borra."
PRINT TAB(0,2);STRING$(64,CHR$136);
FOR F%=1 TO 6:PRINT TAB(0,1+F%*2);LB$(F%);": ";FNdato(I%,F%);:NEXT
VDU 23,1,1;0;0;0;
FOR F%=1 TO 6
VDU 28,0,2+F%*2,63,2+F%*2
PRINT SPC(LEN(LB$(F%)));"> ";
INPUT LINE "" N$
VDU 26
WHILE LEFT$(N$,1)=" ":N$=MID$(N$,2):ENDWHILE
IF N$="-" THEN PROCponer(I%,F%,"") ELSE IF N$<>"" THEN PROCponer(I%,F%,LEFT$(N$,LG%(F%)))
IF F%=5 THEN PROCcumple(I%)
PRINT TAB(0,1+F%*2);LB$(F%);": ";FNdato(I%,F%);SPC(60-LEN(LB$(F%))-LEN(FNdato(I%,F%)));
NEXT
VDU 23,1,0;0;0;0;
PROCclave(I%)
PROCubicar(I%)
PROCgrabar
ENDPROC
#
DEF FNdato(I%,F%)
IF F%=1 THEN =NO$(I%)
IF F%=2 THEN =TE$(I%)
IF F%=3 THEN =DI$(I%)
IF F%=4 THEN =CO$(I%)
IF F%=5 THEN =CU$(I%)
=NT$(I%)
#
DEF PROCponer(I%,F%,V$)
IF F%=1 THEN NO$(I%)=V$
IF F%=2 THEN TE$(I%)=V$
IF F%=3 THEN DI$(I%)=V$
IF F%=4 THEN CO$(I%)=V$
IF F%=5 THEN CU$(I%)=V$
IF F%=6 THEN NT$(I%)=V$
ENDPROC
#
REM El cumpleaños se guarda como dd/mm
DEF PROCcumple(I%)
LOCAL D%,M%,P%
IF CU$(I%)="" THEN ENDPROC
D%=VAL(CU$(I%)):P%=INSTR(CU$(I%),"/")
IF P%=0 THEN P%=INSTR(CU$(I%),"-")
IF P%>0 THEN M%=VAL(MID$(CU$(I%),P%+1))
IF D%<1 OR D%>31 OR M%<1 OR M%>12 THEN CU$(I%)="":PRINT TAB(40,11);"(fecha no válida)"; ELSE CU$(I%)=RIGHT$("0"+STR$(D%),2)+"/"+RIGHT$("0"+STR$(M%),2)
ENDPROC
#
REM Clave para ordenar: el nombre en mayúsculas y sin acentos
DEF PROCclave(I%)
LOCAL J%,C%,P%
KY$(I%)=NO$(I%)
FOR J%=1 TO LEN(KY$(I%))
C%=ASC(MID$(KY$(I%),J%,1))
IF C%>=97 AND C%<=122 THEN C%=C%-32
P%=INSTR(CHR$225+CHR$233+CHR$237+CHR$243+CHR$250+CHR$252+CHR$241+CHR$193+CHR$201+CHR$205+CHR$211+CHR$218+CHR$220+CHR$209,CHR$C%)
IF P%>0 THEN C%=ASC(MID$("AEIOUUNAEIOUUN",P%,1))
MID$(KY$(I%),J%,1)=CHR$C%
NEXT
ENDPROC
#
REM Mueve la persona I% hasta su lugar en el orden alfabético
DEF PROCubicar(I%)
WHILE I%>1 AND FNantes(I%,I%-1):PROCcambiar(I%,I%-1):I%=I%-1:ENDWHILE
WHILE I%<NR% AND FNantes(I%+1,I%):PROCcambiar(I%,I%+1):I%=I%+1:ENDWHILE
SE%=I%
ENDPROC
#
DEF FNantes(A%,B%)
=KY$(A%)<KY$(B%)
#
REM Intercambia dos personas usando el lugar 0 como auxiliar
DEF PROCcambiar(A%,B%)
PROCcopiar(A%,0):PROCcopiar(B%,A%):PROCcopiar(0,B%)
ENDPROC
#
DEF PROCcopiar(A%,B%)
NO$(B%)=NO$(A%):TE$(B%)=TE$(A%):DI$(B%)=DI$(A%)
CO$(B%)=CO$(A%):CU$(B%)=CU$(A%):NT$(B%)=NT$(A%):KY$(B%)=KY$(A%)
ENDPROC
#
DEF PROCborrar(I%)
LOCAL K%
K%=FNpregunta("¿Borrar a "+LEFT$(NO$(I%),30)+"? (S/N)")
IF K%<>83 THEN ENDPROC
PROCquitar(I%)
PROCgrabar
FIL%=0:PROClista
ENDPROC
#
DEF PROCquitar(I%)
WHILE I%<NR%:PROCcopiar(I%+1,I%):I%=I%+1:ENDWHILE
NR%=NR%-1
IF SE%>NR% THEN SE%=NR%
IF SE%<1 THEN SE%=1
IF ARR%>SE% THEN ARR%=SE%
ENDPROC
#
REM ---------------- Búsqueda ----------------
DEF PROCbuscar
LOCAL I%,V%,H%
IF NR%=0 THEN ENDPROC
PRINT TAB(0,15);SPC(63);
VDU 28,0,15,63,15,12,23,1,1;0;0;0;
PRINT "Buscar (Enter = ";B$;"): ";
INPUT LINE "" N$
VDU 26,23,1,0;0;0;0;
IF N$<>"" THEN B$=LEFT$(N$,40)
IF B$="" THEN PROClista:ENDPROC
I%=SE%:V%=0:H%=FALSE
REPEAT
I%=I%+1:IF I%>NR% THEN I%=1
V%=V%+1
IF INSTR(NO$(I%)+TE$(I%)+DI$(I%)+CO$(I%)+NT$(I%),B$)>0 THEN H%=TRUE
UNTIL H% OR V%>=NR%
FIL%=0:PROClista
IF H% THEN SE%=I%:PROCver ELSE PROCaviso("No encontré "+B$)
ENDPROC
#
REM ---------------- Cumpleaños ----------------
DEF FNhoy
LOCAL T$,D%,M%
T$=TIME$
D%=VAL(MID$(T$,5,2)):M%=(INSTR("EneFebMarAbrMayJunJulAgoSepOctNovDic",MID$(T$,8,3))+2) DIV 3
=TT%(M%)+D%
#
REM Días que faltan para el cumpleaños de I% (0 = hoy, -1 = sin fecha)
DEF FNfaltan(I%,H%)
LOCAL D%,M%,N%
IF CU$(I%)="" THEN =-1
D%=VAL(CU$(I%)):M%=VAL(MID$(CU$(I%),4))
N%=TT%(M%)+D%-H%
IF N%<0 THEN N%=N%+365
=N%
#
DEF PROCcumples
LOCAL H%,I%,R%,B%,M%,Q%
H%=FNhoy
FOR I%=1 TO NR%:FA%(I%)=FNfaltan(I%,H%):NEXT
CLS
PRINT TAB(0,0);"PRÓXIMOS CUMPLEAÑOS"
PRINT TAB(0,1);STRING$(64,CHR$136);
R%=2
REPEAT
B%=0:M%=999
FOR I%=1 TO NR%:IF FA%(I%)>=0 AND FA%(I%)<M% THEN M%=FA%(I%):B%=I%
NEXT
IF B%>0 THEN PROCrenglon(B%,M%):FA%(B%)=-1:R%=R%+1
UNTIL B%=0 OR R%>=15
IF R%=2 THEN PRINT TAB(2,4);"Nadie tiene anotado el cumpleaños."
PRINT TAB(0,15);"Apretá una tecla para volver a la lista";
Q%=GET
FIL%=0:PROClista
ENDPROC
#
DEF PROCrenglon(I%,N%)
PRINT TAB(2,R%);CU$(I%);"  ";LEFT$(NO$(I%),32);TAB(44,R%);
IF N%=0 THEN PRINT "¡HOY!"; ELSE IF N%=1 THEN PRINT "mañana"; ELSE PRINT "en ";N%;" días";
ENDPROC
#
REM Al entrar avisa los cumpleaños de los próximos 7 días
DEF PROCavisos
LOCAL H%,I%,N%
IF NR%=0 THEN ENDPROC
H%=FNhoy:S$=""
FOR I%=1 TO NR%
N%=FNfaltan(I%,H%)
IF N%>=0 AND N%<=7 AND LEN(S$)<40 THEN S$=S$+LEFT$(NO$(I%),INSTR(NO$(I%)+" "," ")-1)+FNcuando(N%)+"  "
NEXT
IF S$<>"" THEN PROCaviso("Cumpleaños: "+S$)
ENDPROC
#
DEF FNcuando(N%)
IF N%=0 THEN =" (hoy)"
IF N%=1 THEN =" (mañana)"
=" ("+STR$(N%)+" días)"
#
REM ---------------- Archivo ----------------
DEF PROCcargar
LOCAL F%,I%
F%=OPENIN "AGENDA.DAT"
IF F%=0 THEN ENDPROC
WHILE NOT EOF#F% AND NR%<MR%
NR%=NR%+1
NO$(NR%)=LEFT$(GET$#F%,30):TE$(NR%)=LEFT$(GET$#F%,20):DI$(NR%)=LEFT$(GET$#F%,32)
CO$(NR%)=LEFT$(GET$#F%,32):CU$(NR%)=LEFT$(GET$#F%,5):NT$(NR%)=LEFT$(GET$#F%,32)
IF NO$(NR%)="" THEN NR%=NR%-1 ELSE PROCclave(NR%)
ENDWHILE
CLOSE#F%
ENDPROC
#
REM Graba toda la agenda (6 líneas de texto por persona)
DEF PROCgrabar
LOCAL F%,I%
F%=OPENOUT "AGENDA.DAT"
FOR I%=1 TO NR%
BPUT#F%,NO$(I%):BPUT#F%,TE$(I%):BPUT#F%,DI$(I%)
BPUT#F%,CO$(I%):BPUT#F%,CU$(I%):BPUT#F%,NT$(I%)
NEXT
CLOSE#F%
ENDPROC
#
REM ---------------- Mensajes ----------------
DEF PROCaviso(M$)
LOCAL K%
PRINT TAB(0,15);SPC(63);TAB(0,15);LEFT$(M$,63);
K%=GET
PRINT TAB(0,15);"F1 Nueva F2 Cambiar F3 Borrar F4 Buscar F5 Cumpleaños  Volver";
ENDPROC
#
DEF FNpregunta(M$)
LOCAL K%
PRINT TAB(0,15);SPC(63);TAB(0,15);M$;
K%=GET
IF K%>=97 AND K%<=122 THEN K%=K%-32
=K%
#
DEF PROCsalir
*ESC ON
?&FA96=MAY%
CHAIN "MENU"
ENDPROC
#
{error} CLOSE#0:VDU 26,23,1,0;0;0;0;
IF ERR=0 THEN PROCaviso("La memoria está llena") ELSE PROCaviso(REPORT$)
FIL%=0:PROClista
GOTO {bucle}
#
{datos} DATA Nombre,30,Teléfono,20,Dirección,32,Correo,32,Cumpleaños (dd/mm),5,Nota,32
DATA 0,31,59,90,120,151,181,212,243,273,304,334
