# NOTAS - editor de textos: escribí, grabá y abrí tus notas
REM NOTAS - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 0
*ESC OFF
MX%=200:AN%=62:FI%=14
DIM L$(MX%),LI$(42),B% 40
REM Cada línea se reserva con 63 lugares para no gastar memoria al editar
FOR I%=1 TO MX%:L$(I%)=STRING$(63," "):L$(I%)="":NEXT
FOR I%=1 TO 42:LI$(I%)=STRING$(16," "):LI$(I%)="":NEXT
REM Los textos de trabajo también se reservan de entrada (el BASIC no recupera
REM la memoria de las cadenas que crecen)
T$=STRING$(255," "):N$=STRING$(63," "):S$=STRING$(31," "):B$=STRING$(63," ")
M$=STRING$(63," "):A$=STRING$(63," "):R$=STRING$(31," "):NOM$=STRING$(20," ")
B$="":M$="":A$="":R$="":NOM$=""
MAY%=?&FA96:?&FA96=0
PROCnuevo
{bucle} REPEAT
PROCcursor
K%=GET
IF (K%>=32 AND K%<127) OR K%>=160 THEN PROCinserta(K%) ELSE PROCtecla(K%)
UNTIL FALSE
#
DEF PROCnuevo
NL%=1:L$(1)="":CX%=0:CY%=1:ARR%=1:CAMB%=FALSE:NOM$=""
PROCtodo
ENDPROC
#
DEF PROCtodo
CLS
PROCtitulo
PROCayudita
PROCdesde(ARR%)
ENDPROC
#
DEF PROCayudita
PRINT TAB(0,15);"F1 Grabar F2 Abrir F3 Nuevo F4 Buscar F5 Ayuda   Volver: salir";
ENDPROC
#
DEF PROCtitulo
T$=NOM$:IF T$="" THEN T$="(sin nombre)"
IF CAMB% THEN T$=T$+" *"
PRINT TAB(0,0);SPC(45);TAB(0,0);"NOTAS: ";T$;
VDU 31,CX%,CY%-ARR%+1
ENDPROC
#
DEF PROCcursor
S$="Lín "+STR$(CY%)+"/"+STR$(NL%)+" Col "+STR$(CX%+1)
PRINT TAB(45,0);RIGHT$("                  "+S$,18);
VDU 31,CX%,CY%-ARR%+1
ENDPROC
#
REM Escribe las líneas desde la N% hasta el final de la pantalla
DEF PROCdesde(N%)
LOCAL I%
IF N%<ARR% THEN N%=ARR%
I%=N%
WHILE I%<ARR%+FI%
PROCfila(I%)
I%=I%+1
ENDWHILE
ENDPROC
#
DEF PROCfila(I%)
IF I%<=NL% THEN PRINT TAB(0,I%-ARR%+1);L$(I%);SPC(63-LEN(L$(I%))); ELSE PRINT TAB(0,I%-ARR%+1);SPC(63);
ENDPROC
#
DEF PROCcambio
IF NOT CAMB% THEN CAMB%=TRUE:PROCtitulo
ENDPROC
#
REM Se asegura de que la línea del cursor esté en pantalla
DEF PROCvisible
IF CY%=ARR%-1 THEN ARR%=CY%:VDU 28,0,FI%,63,1,30,11,26:PROCfila(CY%):ENDPROC
IF CY%=ARR%+FI% THEN ARR%=ARR%+1:VDU 28,0,FI%,63,1,31,0,FI%-1,10,26:PROCfila(CY%):ENDPROC
IF CY%<ARR% THEN ARR%=CY%:PROCdesde(ARR%):ENDPROC
IF CY%>=ARR%+FI% THEN ARR%=CY%-FI%+1:PROCdesde(ARR%)
ENDPROC
#
DEF PROCinserta(K%)
PROCcambio
T$=L$(CY%)
L$(CY%)=LEFT$(T$,CX%)+CHR$K%+MID$(T$,CX%+1)
CX%=CX%+1
IF LEN(L$(CY%))>AN% THEN PROCcorta:ENDPROC
IF CX%=LEN(L$(CY%)) THEN VDU K% ELSE PRINT TAB(CX%-1,CY%-ARR%+1);MID$(L$(CY%),CX%);
ENDPROC
#
REM La línea se pasó del ancho: la última palabra baja a una línea nueva
DEF PROCcorta
LOCAL P%,OY%
IF NL%>=MX% THEN T$=L$(CY%):L$(CY%)=LEFT$(T$,CX%-1)+MID$(T$,CX%+1):CX%=CX%-1:PROCaviso("El texto llegó al máximo de líneas"):ENDPROC
T$=L$(CY%):OY%=CY%
PROCcorte
PROCabre(CY%+1)
L$(CY%)=LEFT$(T$,H%):L$(CY%+1)=MID$(T$,S%)
IF CX%>H% THEN CX%=CX%-(S%-1):CY%=CY%+1
IF CX%<0 THEN CX%=0
PROCvisible
PROCdesde(OY%)
ENDPROC
#
REM Dónde cortar la línea larga T$: en el último espacio que entra o en el
REM ancho máximo. H% = largo de la primera parte, S% = comienzo de la segunda
DEF PROCcorte
LOCAL Q%,P%
Q%=AN%+1
WHILE Q%>1 AND P%=0
IF MID$(T$,Q%,1)=" " THEN P%=Q%
Q%=Q%-1
ENDWHILE
IF P%=0 THEN H%=AN%:S%=AN%+1 ELSE H%=P%-1:S%=P%+1
ENDPROC
#
REM Abre un lugar vacío en la línea N%
DEF PROCabre(N%)
LOCAL I%
I%=NL%
WHILE I%>=N%
L$(I%+1)=L$(I%)
I%=I%-1
ENDWHILE
L$(N%)="":NL%=NL%+1
ENDPROC
#
REM Quita la línea N%
DEF PROCcierra(N%)
LOCAL I%
I%=N%
WHILE I%<NL%
L$(I%)=L$(I%+1)
I%=I%+1
ENDWHILE
L$(NL%)="":NL%=NL%-1
ENDPROC
#
DEF PROCtecla(K%)
IF K%=136 THEN PROCizq
IF K%=137 THEN PROCder
IF K%=139 AND CY%>1 THEN CY%=CY%-1:PROCajusta
IF K%=138 AND CY%<NL% THEN CY%=CY%+1:PROCajusta
IF K%=142 THEN CX%=0
IF K%=143 THEN CX%=LEN(L$(CY%))
IF K%=140 THEN CY%=CY%-(FI%-1):IF CY%<1 THEN CY%=1
IF K%=141 THEN CY%=CY%+(FI%-1):IF CY%>NL% THEN CY%=NL%
IF K%=140 OR K%=141 THEN PROCajusta
IF K%=13 THEN PROCenter
IF K%=127 OR K%=8 THEN PROCborra
IF K%=135 THEN PROCsuprime
IF K%=129 THEN PROCgrabar
IF K%=130 THEN PROCabrir
IF K%=131 THEN PROCnueva
IF K%=132 THEN PROCbuscar
IF K%=133 THEN PROCayuda
IF K%=27 OR K%=128 THEN PROCsalir
ENDPROC
#
DEF PROCajusta
IF CX%>LEN(L$(CY%)) THEN CX%=LEN(L$(CY%))
PROCvisible
ENDPROC
#
DEF PROCizq
IF CX%>0 THEN CX%=CX%-1:ENDPROC
IF CY%>1 THEN CY%=CY%-1:CX%=LEN(L$(CY%)):PROCvisible
ENDPROC
#
DEF PROCder
IF CX%<LEN(L$(CY%)) THEN CX%=CX%+1:ENDPROC
IF CY%<NL% THEN CY%=CY%+1:CX%=0:PROCvisible
ENDPROC
#
REM Enter: parte la línea en el cursor
DEF PROCenter
IF NL%>=MX% THEN PROCaviso("El texto llegó al máximo de líneas"):ENDPROC
T$=L$(CY%)
PROCabre(CY%+1)
L$(CY%)=LEFT$(T$,CX%):L$(CY%+1)=MID$(T$,CX%+1)
CY%=CY%+1:CX%=0:PROCcambio
PROCvisible
PROCdesde(CY%-1)
ENDPROC
#
REM Borrar: quita la letra de la izquierda (al principio, une con la línea de arriba)
DEF PROCborra
IF CX%>0 THEN T$=L$(CY%):L$(CY%)=LEFT$(T$,CX%-1)+MID$(T$,CX%+1):CX%=CX%-1:PROCcambio:PRINT TAB(CX%,CY%-ARR%+1);MID$(L$(CY%),CX%+1);" ";:ENDPROC
IF CY%=1 THEN ENDPROC
IF LEN(L$(CY%-1))+LEN(L$(CY%))>AN% THEN VDU 7:ENDPROC
CX%=LEN(L$(CY%-1)):L$(CY%-1)=L$(CY%-1)+L$(CY%)
PROCcierra(CY%):CY%=CY%-1:PROCcambio
PROCvisible
PROCdesde(CY%)
ENDPROC
#
REM Imprimir (suprimir): quita la letra del cursor (al final, une con la de abajo)
DEF PROCsuprime
IF CX%<LEN(L$(CY%)) THEN T$=L$(CY%):L$(CY%)=LEFT$(T$,CX%)+MID$(T$,CX%+2):PROCcambio:PRINT TAB(CX%,CY%-ARR%+1);MID$(L$(CY%),CX%+1);" ";:ENDPROC
IF CY%=NL% THEN ENDPROC
IF LEN(L$(CY%))+LEN(L$(CY%+1))>AN% THEN VDU 7:ENDPROC
L$(CY%)=L$(CY%)+L$(CY%+1)
PROCcierra(CY%+1):PROCcambio
PROCdesde(CY%)
ENDPROC
#
REM Mensaje en la última fila hasta que se apriete una tecla
DEF PROCaviso(M$)
LOCAL K%
PRINT TAB(0,15);SPC(63);TAB(0,15);LEFT$(M$,50);"  (una tecla)";
K%=GET
PROCayudita
ENDPROC
#
REM Pregunta en la última fila; devuelve la tecla en mayúscula
DEF FNpregunta(M$)
LOCAL K%
PRINT TAB(0,15);SPC(63);TAB(0,15);M$;
K%=GET
IF K%>=97 AND K%<=122 THEN K%=K%-32
PROCayudita
=K%
#
REM Pide un texto en la última fila (Enter solo = cancelar); queda en N$
DEF PROCpide(M$)
PRINT TAB(0,15);SPC(63);
VDU 28,0,15,63,15,12
PRINT M$;
INPUT LINE "" N$
VDU 26
WHILE LEFT$(N$,1)=" ":N$=MID$(N$,2):ENDWHILE
PROCayudita
ENDPROC
#
REM Arma un nombre de archivo válido en N$ (mayúsculas, .TXT si no tiene)
DEF PROCnombre
LOCAL I%,C%
FOR I%=1 TO LEN(N$)
C%=ASC(MID$(N$,I%,1))
IF C%>=97 AND C%<=122 THEN N$=LEFT$(N$,I%-1)+CHR$(C%-32)+MID$(N$,I%+1)
NEXT
IF INSTR(N$,".")=0 THEN N$=N$+".TXT"
ENDPROC
#
DEF PROCgrabar
LOCAL F%,I%,K%
IF NOM$="" THEN PROCpide("Nombre del archivo (Enter = cancelar): ") ELSE PROCpide("Nombre (Enter = "+NOM$+"): "):IF N$="" THEN N$=NOM$
IF N$="" THEN ENDPROC
PROCnombre
IF LEN(N$)>16 THEN PROCaviso("El nombre es demasiado largo (máximo 16)"):ENDPROC
IF N$<>NOM$ THEN F%=OPENIN N$ ELSE F%=0
IF F%>0 THEN CLOSE#F%:K%=FNpregunta(N$+" ya existe. ¿Reemplazarlo? (S/N)"):IF K%<>83 THEN ENDPROC
PRINT TAB(0,15);SPC(63);TAB(0,15);"Grabando ";N$;"...";
F%=OPENOUT N$
FOR I%=1 TO NL%:BPUT#F%,L$(I%):NEXT
CLOSE#F%
NOM$=N$:CAMB%=FALSE:PROCtitulo
PROCaviso("Grabado: "+NOM$+" ("+STR$(NL%)+" líneas)")
ENDPROC
#
DEF PROCabrir
LOCAL F%,K%
IF CAMB% THEN K%=FNpregunta("Hay cambios sin grabar. ¿Abrir otro igual? (S/N)"):IF K%<>83 THEN ENDPROC
N$=FNelegir
IF N$="" THEN PROCtodo:ENDPROC
PROCleer(N$)
ENDPROC
#
DEF PROCleer(A$)
LOCAL F%,P%,MAS%
CLS:PRINT TAB(0,15);"Leyendo ";A$;"...";
F%=OPENIN A$
IF F%=0 THEN PROCtodo:PROCaviso("No encuentro "+A$):ENDPROC
NL%=0:MAS%=FALSE
WHILE NOT EOF#F% AND NOT MAS%
T$=GET$#F%
REPEAT
IF NL%>=MX% THEN MAS%=TRUE ELSE PROCtrozo
UNTIL T$="" OR MAS%
ENDWHILE
CLOSE#F%
IF NL%=0 THEN NL%=1:L$(1)=""
NOM$=A$:CX%=0:CY%=1:ARR%=1:CAMB%=FALSE
PROCtodo
IF MAS% THEN PROCaviso("El archivo es largo: se leyeron "+STR$(MX%)+" líneas")
ENDPROC
#
REM Pasa a una línea el primer pedazo de T$ que entra en el ancho
DEF PROCtrozo
NL%=NL%+1
IF LEN(T$)<=AN% THEN L$(NL%)=T$:T$="":ENDPROC
PROCcorte
L$(NL%)=LEFT$(T$,H%)
T$=MID$(T$,S%)
ENDPROC
#
REM Lista los archivos de texto (.TXT) de los dos discos y deja elegir uno
DEF FNelegir
LOCAL N%,I%,K%,S%,X%,Y%
N%=0:I%=0
REPEAT
!B%=I%:A%=192:X%=B% MOD 256:Y%=B% DIV 256:CALL &FFF1
IF ?B%=0 AND N%<42 THEN N$=FNcampo(B%+2):IF RIGHT$(N$,4)=".TXT" THEN N%=N%+1:LI$(N%)=N$
I%=I%+1
UNTIL ?B%=2
CLS
PRINT TAB(0,0);"ABRIR: elegí un archivo con las flechas y apretá Enter";
IF N%=0 THEN PROCaviso("No hay archivos de texto (.TXT) en el disco"):=""
PRINT TAB(0,15);"Flechas: elegir   Enter: abrir   Volver: cancelar";
FOR I%=1 TO N%:PROCopcion(I%,FALSE):NEXT
S%=1
REPEAT
PROCopcion(S%,TRUE)
K%=GET
PROCopcion(S%,FALSE)
IF K%=136 AND S%>14 THEN S%=S%-14
IF K%=137 AND S%+14<=N% THEN S%=S%+14
IF K%=139 AND S%>1 THEN S%=S%-1
IF K%=138 AND S%<N% THEN S%=S%+1
UNTIL K%=13 OR K%=27
IF K%=27 THEN =""
=LI$(S%)
#
DEF PROCopcion(I%,M%)
IF M% THEN COLOUR 129:COLOUR 0
PRINT TAB(((I%-1) DIV 14)*21,1+(I%-1) MOD 14);" ";LI$(I%);SPC(17-LEN(LI$(I%)));
COLOUR 128:COLOUR 1
ENDPROC
#
DEF FNcampo(A%)
R$=""
WHILE ?A%>32 AND LEN(R$)<16:R$=R$+CHR$?A%:A%=A%+1:ENDWHILE
=R$
#
DEF PROCnueva
LOCAL K%
IF CAMB% THEN K%=FNpregunta("Hay cambios sin grabar. ¿Empezar otro igual? (S/N)"):IF K%<>83 THEN ENDPROC
PROCnuevo
ENDPROC
#
REM Busca un texto desde el cursor hacia abajo (y vuelve a empezar arriba)
DEF PROCbuscar
LOCAL I%,P%,V%
PROCpide("Buscar (Enter = "+B$+"): ")
IF N$<>"" THEN B$=LEFT$(N$,63)
IF B$="" THEN ENDPROC
I%=CY%:P%=INSTR(L$(I%),B$,CX%+2)
WHILE P%=0 AND V%<=NL%
I%=I%+1:V%=V%+1:IF I%>NL% THEN I%=1
P%=INSTR(L$(I%),B$)
ENDWHILE
IF P%=0 THEN PROCaviso("No encontré "+B$):ENDPROC
CY%=I%:CX%=P%-1
PROCvisible
ENDPROC
#
DEF PROCayuda
CLS
PRINT TAB(0,0);"NOTAS - AYUDA"
PRINT
PRINT " Flechas         mover el cursor"
PRINT " Fn + flechas    principio / fin de línea, página arriba / abajo"
PRINT " Borrar          borra la letra de la izquierda"
PRINT " Imprimir        borra la letra del cursor"
PRINT " Enter           parte la línea (o agrega una nueva)"
PRINT " Bloq Mayús      mayúsculas;  Fn + vocal = acento;  Fn + N = ñ"
PRINT
PRINT " F1 grabar   F2 abrir   F3 empezar otro   F4 buscar"
PRINT " Volver o Menú: salir (pregunta si hay cambios sin grabar)"
PRINT
PRINT " Los textos se graban como archivos .TXT en el disco."
PRINT " Se pueden pasar a la PC con *ENVIAR."
PRINT TAB(0,15);"Apretá una tecla para seguir escribiendo";
K%=GET
PROCtodo
ENDPROC
#
DEF PROCsalir
LOCAL K%
IF CAMB% THEN K%=FNpregunta("Hay cambios sin grabar. ¿Grabarlos? (S/N, Volver = seguir)") ELSE K%=78
IF K%=27 OR K%=128 THEN ENDPROC
IF K%=83 THEN PROCgrabar:IF CAMB% THEN ENDPROC
IF K%<>83 AND K%<>78 THEN ENDPROC
*ESC ON
?&FA96=MAY%
CHAIN "MENU"
ENDPROC
#
{error} CLOSE#0:VDU 26
IF ERR=0 THEN PROCaviso("La memoria está llena: grabá el texto") ELSE PROCaviso(REPORT$)
GOTO {bucle}
