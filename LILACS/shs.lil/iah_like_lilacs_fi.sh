#!/bin/bash

# -------------------------------------------------------------------------- #
# iah_fi.sh - Processamento basico de FI para iAH                            #
# -------------------------------------------------------------------------- #
# Chamada : iah_fi.sh [-V] <ID_FI>
# Exemplo : nohup ../shs.lil/iah_fi.sh bde &> logs/$(date '+%Y%m%d').IAH.txt &
# -------------------------------------------------------------------------- #
#  Centro Latino-Americano e do Caribe de Informação em Ciências da Saúde    #
#     é um centro especialidado da Organização Pan-Americana da Saúde,       #
#           escritório regional da Organização Mundial da Saúde              #
#                      BIREME / OPS / OMS (P)2012-16                         #
# -------------------------------------------------------------------------- #
# Historico
# Versao data, responsavel
#       - Descricao
cat > /dev/null <<HISTORICO
vrs:  0.00 20160608, FJLopes
	- Edicao original
HISTORICO

# ========================================================================== #
#                                BIBLIOTECAS                                 #
# ========================================================================== #
# Incorpora biblioteca de controle basico de processamento
source  $MISC/infra/infoini.inc

# Incorpora biblioteca de processos de coleta
source ../shs.lil/inc/coletas.inc

# Assume valores DEFAULT
NOERRO=0;	# Controla o modo "Ignore Erros"
DEBUG=0;	# Controla o nivel de depuracao

# Mensagem de HELP
#        1         2         3         4         5         6         7         8
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
AJUDA_USO="
This process generates the basic indexes for uso with iAH.
Uso: $TREXE <ID_FI>

Options:
 -V, --version       Displays the current version of program and stop

Parameters:
ID_FI - Identifier of Information Source to process 

"

# Tratador de opcoes
while test -n "$1"
do
	case "$1" in
		-V | --version)
			iVersao
			echo
			exit 0
			;;

		*)
			if [ $(expr index $1 "-") -ne 1 ]; then
				if test -z "$PARM1";  then PARM1=$1;  shift; shift; continue; fi
				if test -z "$PARM2";  then PARM2=$1;  shift; shift; continue; fi
			else
				echo "Not valid option ($1)"
			fi
			;;
	esac
	# Argumento tratado, desloca os parametros e trata o proximo (se existir)
	shift
done

# Avalia o nivel de depuracao
[ $((DEBUG & $_BIT3_)) -ne 0 ] && -v
[ $((DEBUG & $_BIT4_)) -ne 0 ] && -x

# ========================================================================== #
#     1234567890123456789012345
echo "[iahfi]  1         - Inicia processamento de geracao de indices iah basicos"
# -------------------------------------------------------------------------- #
# Garante que a o parametro 1 seja informado (sai com codigo de erro 2 - Syntax Error)
if [ -z "$PARM1" ]; then
        #     1234567890123456789012345
        echo "[iahfi]  1.01      - Erro na chamada falta o parametro 1"
        echo
        echo "Syntax error:- Missing PARM1"
        echo "$AJUDA_USO"
        exit 2
fi
			
# -------------------------------------------------------------------------- #
# Garante existencia da tabela de configuracao (sai com codigo de erro 3 - Configuration Error)
#                                            1234567890123456789012345
[ $N_DEB -ne 0 ]           && echo "[iahfi]  0.00.04   - Testa se ha tabela de configuracao"
[ ! -s "../tabs/coletas.tab" ] && echo "[iahfi]  1.01      - Configuration error:- COLETAS table not found" && exit 3

unset   SIGLA
# Garante existencia do FI indicada na tabela de configuracao (sai com codigo de erro 4 - Configuration Failure)
# alem de tomar nome oficial do indice para processamento
#                         1234567890123456789012345
[ $N_DEB -ne 0 ] && echo "[iahfi]  0.00.05   - Testa se o indice eh valido"
IDFI=$(clANYTHING $PARM1)
[ $? -eq 0 ]     && SIGLA=$(clSIGLA $IDFI)
[ -z "$SIGLA" ]  && echo "[iahfi]  1.01      - PARM error:- PARM1 does not indicate a valid index" && exit 4

echo "[iahfi]  1.01      - Carrega definicoes da fonte para coleta de dados"
  TIPOC=$(clTYPE       $IDFI)
 DIRETO=$(clDIRETORIO  $IDFI)
SSERVER=$(clSSERVER    $IDFI)
SDIRETO=$(clSDIRETORIO $IDFI)
 OBJETO=$(clOBJETOS    $IDFI)
  PORTA=$(clPORT       $IDFI)
 USERCL=$(clUSER       $IDFI)
 PASSCL=$(clPASSWD     $IDFI)

# -------------------------------------------------------------------------- #
# Faz corrente o diretorio de processamento
echo "[iahfi]  1.02      - Faz corrente o diretorio de processamento"
cd $DIRETO

echo "[iahfi]  1.03      - Normaliza denominacao da M/F de entrada"
# Verifica se existe ${IDFI}_saneada.mst ou ${IDFI}_saneada2.mst, caso nenhuma exista eh erro
RSP=0; [ ! -f ${IDFI}_lil_saneada.xrf -a ! -f ${IDFI}_lil_saneada2.xrf ] && RSP=7
[ "$NOERRO" = "1" ] && RSP=0
chkError $RSP "${IDFI} master file is unavailable or unreachable"

echo "[iahfi]  1.03.01   - Substitui resultado de pos_saneamento pelo de saneamento"
[ -f "${IDFI}_lil_saneada2.mst" ] || mv ${IDFI}_lil_saneada.mst ${IDFI}_lil_saneada2.mst 
[ -f "${IDFI}_lil_saneada2.xrf" ] || mv ${IDFI}_lil_saneada.xrf ${IDFI}_lil_saneada2.xrf

# Adequa as condicoes do processamento LILACS
echo "[iahfi]  1.03.02   - Ajusta para condicoes de processamento"
mv ${IDFI}_lil_saneada2.mst lil.mst
mv ${IDFI}_lil_saneada2.xrf lil.xrf

# IMPORTANTE: a entrada deste processo eh a base de dados "lil.mst" (representa a LILACS.mst ao final do saneamento)

#----------------------------------------------------------------------#
# Gera a base de dados de mail para processamento

echo "[iahfi]  2         - Normaliza denominacao da M/F de entrada"

echo "[iahfi]  2.01      - Geracao de mail para ${IDFI}"
MSG="Erro na geracao do mail"
../tpl.lil/genlilmail.sh lil ../tpl.mail/nmail mail
RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
chkError $RSP "$MSG"

#----------------------------------------------------------------------#
# Inicializa o processo geracao dos invertidos MH

echo "[iahfi]  2.01      - Faselilmh - Geracao de invertidos de MH para ${IDFI}"
MSG="Erro na Faselilmh"
../tpl.lil/faselilmh.sh lil 50000
RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
chkError $RSP "$MSG"

#----------------------------------------------------------------------#
# Inicializa o processo geracao dos invertidos de TEXT WORD - TW

echo "[iahfi]  2.02      - Faseliltw - Geracao de invertidos de TEXT WORK  (TW) para ${IDFI}"
MSG="Erro na Faseliltw"
../tpl.lil/faseliltw lil 50000
RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
chkError $RSP "$MSG"

#----------------------------------------------------------------------#
# Inicializa o processo geracao dos outros invertidos simples.

echo "[iahfi]  2.03      - Faseliln - Geracao de outros invertidos para ${IDFI}"
MSG="Erro na Faseliln"
../tpl.lil/faseliln.sh lil
RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
chkError $RSP "$MSG"

# -------------------------------------------------------------------- #
# Acertos finais nos indices gerados e limpeza de area de trabalho
echo "[iahfi]  3         - Finalizacao do processamento de ${IDFI}"

# Gera IY0 - 21/05/2007
echo "[iahfi]  3.01      - Compactacao de indices de ${IDFI}"
MSG="Erro: GENIY0ALL.SH"
../tpl.lil/geniy0all.sh $1
RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
chkError $RSP "$MSG"

echo "[iahfi]  3.02      - Limpeza do diretorio"
MSG="Erro: LIMPALIL.SH "
../tpl.lil/limpalil.sh $1
RSP=$?; [ "$NOERRO" = "1" ] && RSP=0
chkError $RSP "$MSG"

# -------------------------------------------------------------------------- #
# Incorpora biblioteca de controle basico de processamento
source  $MISC/infra/infofim.inc

exit 0






cat > /dev/null <<COMMENT
.    Entrada : PARM1 com o identificador da FI (<IDFI>)
.      Saida : M/F e I/F para uso com iAH
.   Corrente : --
.    Chamada : ../shs.lil/iah_fi.sh [-V] <IDFI>
.Objetivo(s) : Criar o minimo necessario de M/F e I/F para uso em iAH
.Comentarios :
.Observacoes :
.Dependencia : Tabela coletas.tab deve estar presente em ../tabs
.               COLUNA  NOME                    COMENTARIOS
.                1      ID_FI               ID da Fonte de Informacao     (Identificador unico)
.                2      SIGLA FI            Nome humano da FI
.                3      DIRETORIO           Diretorio de entrega dos dados
.                4      TIPO                Tipo de coleta para aFI (valores: scp / ftp / rsync / oai / dSpace)
.                5      FONTE DE DADOS      (todos os subcampos devem ser declarados ainda que vazios)
.                       ^h=                 HOSTNAME onde se encontram os dados
.                       ^d=                 Diretorio dos dados na fonte
.                       ^l=                 PORT TCP/IP a ser utilizado (quando cabivel)
.                       ^p=                 Username a ser utilizado no processo
.                       ^s=                 Senha do ususario a ser empregada na autenticacao
.                       ^b=                 Lista de arquivos (separados por ;) a coletar
.               Variaveis de ambiente que devem estar previamente ajustadas:
.               geral           BIREME - Path para o diretorio com especificos da BIREME
.               geral             CRON - Path para o diretorio com rotinas de crontab
.               geral             MISC - Path para o diretorio de miscelaneas da BIREME
.               geral             TABS - Path para as tabelasde uso geral da BIREME
.               geral         TRANSFER - Usuario para troca de arquivos entre servidores
.               geral           _BIT0_ - 00000001b
.               geral           _BIT1_ - 00000010b
.               geral           _BIT2_ - 00000100b
.               geral           _BIT3_ - 00001000b
.               geral           _BIT4_ - 00010000b
.               geral           _BIT5_ - 00100000b
.               geral           _BIT6_ - 01000000b
.               geral           _BIT7_ - 10000000b
.               ISIS         ISIS - WXISI      - Path para pacote
.               ISIS     ISIS1660 - WXIS1660   - Path para pacote
.               ISIS        ISISG - WXISG      - Path para pacote
.               ISIS         LIND - WXISL      - Path para pacote
.               ISIS      LIND512 - WXISL512   - Path para pacote
.               ISIS       LINDG4 - WXISLG4    - Path para pacote
.               ISIS    LIND512G4 - WXISL512G4 - Path para pacote
.               ISIS          FFI - WXISF      - Path para pacote
.               ISIS      FFI1660 - WXISF1660  - Path para pacote
.               ISIS       FFI512 - WXISF512   - Path para pacote
.               ISIS        FFIG4 - WXISFG4    - Path para pacote
.               ISIS       FFI256 - WXISF256   - Path para pacote
.               ISIS     FFI512G4 - WXISF512G4 - Path para pacote

<MOREINFO
Comentarios adicionais caem bem aqui.
COMMENT
cat >/dev/null <<SPICEDHAM
CHANGELOG
20160608 Edicao original do processamento fatorado de LILACS para iAH
SPICEDHAM
