#!/bin/bash

#Jogo da forca

#Numero da versão
BUILD=10
HANGMAN=1
CATEGORIAS_PATH="hangman_categorias/"
ASCII_PATH="ascii_art/"

##AINDA FALTA IMPLEMENTAR:
##levels: quase completo, falta mudar o sistema que seleciona a palavras
##novas artes ascii

help_ (){
	echo "* The Hangman Game *"
	echo "Ajuda:"
	echo "Para criar uma nova categoria, crie um arquivo de texto com o nome da categoria na pasta hangman_categorias com uma lista de palavras. Use -reload"
	echo "Palavras podem conter espaços e hífens, acentos serão removidos."
	echo "Use -default para carregar as categorias default de teste."
	echo "Use -update para baixar o repositório atualizado do script, com novas categorias. Necessário pacote git."
	echo "Use -reload para recarregar categorias, NECESSÁRIO para a engine de levels."
	echo "Use -info para mais informações"
}

info () {
	echo "* The Hangman Game *"

	echo "---------------------"
	echo "Build number:" $BUILD
	echo "---------------------"
}

draw_hangman () {
	./ascii_art/hangman_art.sh $HANGMAN $CHANCES
}

#Futura implementação para multiplos personagens
load_hangmans () {
	HANGMAN_ASCII=(ascii_art/hang_*)
	if [[ ${#HANGMAN_ASCII[@]} == 0 ]]; then
		echo 'Não foi possível carregar a arte ASCII'
		exit 0
	else
		n=0
		for u in ${HANGMAN_ASCII[@]}; do
			if [[ $(ls -1 $u | wc -l ) -lt 6 ]]; then
				unset HANGMAN_ASCII[$n];
				exit 0
			else
				let n++
			fi
		done
	fi
}

#Futura implementação para multiplos personagens
select_hangman () {
	for u in "${HANGMANS[@]}"
	do
		echo $u
	done
	#Vê se há algum pacote de arte Inválido

	echo "***********************************"
	echo "Atual:"
	echo "***********************************"

	read -rsn1 mode # get 1 character

	case $mode in
			'q') echo QUITTING ; exit ;;
			'[A') echo UP ;;
			'[B') echo DN ;;
			'[D') echo LEFT ;;
			'[C') echo RIGHT ;;
			*) >&2 echo 'ERR bad input'; return ;;
	esac

}

#Carrega categorias de teste padrão
test_default () {
	rm -rf hangman_categorias

	mkdir hangman_categorias
	cd hangman_categorias
	printf "cachorro\ngato\nvaca\ntatu" >> "Animais.txt"
	printf "cadeira\njanela\npia\nmesa" >> "Objetos de casa.txt"
}

#Carregar teste_default com diálogo de confirmação
load_default () {
	echo "Você quer carregar as categorias default de teste? [S/N]: "
	read op
	if [[ "$op" == "S" ]] || [[ "$op" == "s" ]]; then
		test_default
	fi
}

get_update () {
	rm -rf hangman
	git clone https://github.com/mrioos/hangman.git
}

setup () {

	#Para a execução do programa se não houver a pasta categorias
	if [[ ! -d "./hangman_categorias" ]]; then
		echo "Erro, pasta Categorias não encontrada."
		echo "Use -help para ver a documentação do jogo."
		load_default
		exit 0
	fi


	#Lê categorias da pasta Categorias e guarda os nomes, em um array
	shopt -s nullglob
	cd hangman_categorias/
	CATEGORIAS_FILES=(*)
	cd ..

	load_hangmans

	n=0

	#Ignora arquivos vazios
	for u in "${CATEGORIAS_FILES[@]}"
	do
		if [[ "$(wc -l < "$CATEGORIAS_PATH${CATEGORIAS_FILES[$n]}")" -eq 0 ]]; then
			unset CATEGORIAS_FILES["$n"];
			let n++;
		fi
	done


	#Se houver 0 itens na array
	if [[ "${#CATEGORIAS_FILES[@]}" -eq 0 ]]; then
		echo "Erro, pasta de categorias vazia."
		echo "Use -help para ver a documentação do jogo."
		load_default
		exit 0
	fi

	n=0

	#Tira as extensões dos arquivos e armazena em CATEGORIAS_NAMES
	for u in "${CATEGORIAS_FILES[@]}"
	do
		CATEGORIAS_NAMES[n]=$(echo ${CATEGORIAS_FILES[n]} | cut -d '.' -f 1 )
		let n++;
	done

	n=0

	#Formata os nomes das categorias
	for u in "${CATEGORIAS_NAMES[@]}"
	do
		CATEGORIAS_NAMES[$n]="$(tr '[:lower:]' '[:upper:]' <<< ${CATEGORIAS_NAMES[$n]:0:1})${CATEGORIAS_NAMES[$n]:1}"
		let n++;
	done

	LEVELS=($CATEGORIAS_PATH".labeled/"*)

}

#Menu de configurações
settings () {
	sort_levels
	clear
	while [[ true ]]; do
		echo "***********************************"
		echo "1. Alterar estilo do hangman"
		echo "2. Voltar"
		echo "***********************************"
		op=-1
		while [[ op -lt 1 ]] || [[ op -gt 2 ]]; do
			printf "Opcão: "
			read -rsn1 op
		done
		case $op in
			1)
			{
				select_hangman
			}
			;;
			2)
			{
				break
			}
			;;

		esac
	done
}

##FUNCIONA 90%
sort_levels () {
	rm -rf $CATEGORIAS_PATH".labeled"
	mkdir $CATEGORIAS_PATH".labeled"
	for u in "${CATEGORIAS_FILES[@]}"; do
		n=0
		for word in $(cat $CATEGORIAS_PATH$u);
		do
			let n++
			#remove repetidas
			word=$(sed -f <(printf 's/%s//2g\n' {a..z}) <<<"$word")
			echo $n","$word >> $CATEGORIAS_PATH".labeled/"$u"_labeled"
			# #adciona linha para um arquivo
		done
		# awk -F, '{print length($2)","$0 | "sort -t',' -nk1 " }' "organized/"$u"_organized" > "organized/"$u"_organized02"
		awk -F, '{ if ( length($2) <= 4 ) print $0}' $CATEGORIAS_PATH".labeled/"$u"_labeled" > $CATEGORIAS_PATH".labeled/"$u"_1"
		awk -F, '{ if ( length($2) >= 5 && length($2) <= 6) print $0}' $CATEGORIAS_PATH".labeled/"$u"_labeled" > $CATEGORIAS_PATH".labeled/"$u"_2"
		awk -F, '{ if ( length($2) >=7 ) print $0}' $CATEGORIAS_PATH".labeled/"$u"_labeled" > $CATEGORIAS_PATH".labeled/"$u"_3"
		rm -f $CATEGORIAS_PATH".labeled/"$u"_labeled"

		for (( n=1 ; n < 4 ; n++ )); do
			if [[ "$(wc -l < $CATEGORIAS_PATH".labeled/"$u"_"$n)" == 0 ]]; then
				rm -f $CATEGORIAS_PATH".labeled/"$u"_"$n
			fi
		done
	done
}

get_palavra () {
	#limpa variáveis
	PALAVRA_RANDOM=()
	PALAVRA=()

	#Escolhe palavra aleatória para o jogo
	N_PALAVRAS="$(wc -l < "$CATEGORIAS_PATH".labeled/"${CATEGORIAS_FILES[$CATEGORIA-1]}"_"$LEVEL")"
	NUMERO=$(( ($RANDOM%$N_PALAVRAS) + 1 ))
	PALAVRA_RANDOM=$(sed "${NUMERO}q;d" $CATEGORIAS_PATH".labeled/"${CATEGORIAS_FILES[$CATEGORIA-1]}"_"$LEVEL)
	PALAVRA_RANDOM=$(sed "${PALAVRA_RANDOM%,*}q;d" $CATEGORIAS_PATH${CATEGORIAS_FILES[$CATEGORIA-1]})

	clear

	#Tira acentos das palavras
	PALAVRA_RANDOM=$(echo ${PALAVRA_RANDOM// /_})
	PALAVRA_RANDOM=$(echo $PALAVRA_RANDOM | iconv -f UTF-8 -t ASCII//TRANSLIT)

	#Transforma palavra em um array de caracteres, e coloca todos em maiúsculo, e guarda em $PALAVRA
	for (( n=0 ; n < ${#PALAVRA_RANDOM} ; n++ )); do
		PALAVRA[$n]=${PALAVRA_RANDOM:$n:1};
		PALAVRA[$n]=$(echo ${PALAVRA[$n]} | tr 'a-z' 'A-Z')
	done

	#procura por mais caracteres estranhos e os remove
	n=0
	for u in "${PALAVRA[@]}"
	do
		if [[ "$u" != [A-Z] ]] && [[ "$u" != [a-z] ]] && [[ "$u" != "_" ]]; then
			PALAVRA[$n]="_";
		else
			let n++
		fi
	done

	FALTA_ADVINHAR=("${PALAVRA[@]}")

	n=0;
	for l in "${FALTA_ADVINHAR[@]}"; do
		if [[ $l == "_" ]]; then
			FALTA_ADVINHAR[$n]=0
		fi
		let n++
	done
}

##FUNCIONA 90%
select_level () {
	clear
	OPTIONS=(0 0 0)

	for l in ${LEVELS[@]}; do
		PAL=${l##*/}
		PAL1=${PAL%_*}
		if [[ $PAL1 == "${CATEGORIAS_FILES[$CATEGORIA-1]}" ]]; then
			PAL2=${PAL#*_}
			if [[ $PAL2 -eq 1 ]]; then echo "1. Fácil"; OPTIONS[0]=1; fi
			if [[ $PAL2 -eq 2 ]]; then echo "2. Médio"; OPTIONS[1]=1; fi
			if [[ $PAL2 -eq 3 ]]; then echo "3. Difícil";OPTIONS[2]=1; fi
		fi
	done
	echo "4. Voltar "

	while [[ true ]]; do
		read -rsn1 LEVEL
		if [[ ${OPTIONS[$LEVEL-1]} -eq 1 ]]; then break; fi
	done

	if [[ $LEVEL -eq 4 ]]; then break; fi
}

select_categoria (){
	clear
	CATEGORIA=-1;

	while [[ "$CATEGORIA" -le 0 ]] || [[ "$CATEGORIA" -gt "$n" ]];
	do
		n=1
		echo "************************************"
		echo "* - - - - - HANGMAN GAME - - - - - *"
		echo "************************************"
		echo "* Escolha uma categoria:           *"
		echo "************************************"
		for u in "${CATEGORIAS_NAMES[@]}"
		do
			echo "$n. $u"
			let n++;
		done
		echo "$n. < Voltar"
		echo "************************************"
		read -rsn1 CATEGORIA
	done
	if [[ "$CATEGORIA" -eq "$n" ]]; then break; fi
}

#Parte principal do jogo
main_game () {
	while [ true ]; do
		select_categoria
		select_level

		#Loop do jogo
		while [[ true ]]; do

			get_palavra $CATEGORIA

			N_ADVINHADOS=0
			CHANCES=6
			TERMINOU=false
			L_TENTATIVAS=()

			while [[ $TERMINOU == false ]]; do

				LETRA=0
				#Organiza letras tentadas em ordem alfabética
				IFS=$'\n' L_TENTATIVAS=($(sort <<<"${L_TENTATIVAS[*]}"))

				while [[ $LETRA != [A-Z] ]] || [[ $LETRA != [a-z] ]]; do
					clear

					#for debugging
					# echo "$($PALAVRA_RANDOM)"

					ACHOU=false
					echo "***********************************"
					echo "* Dica:" ${CATEGORIAS_NAMES[$CATEGORIA-1]}
					echo "***********************************"

					#mostra palavra, tirando letras que ainda faltam mostrar
					printf "* Palavra: "
					n=0
					for l in "${FALTA_ADVINHAR[@]}";
					do
						if [[ $l == 0 ]]; then
							if [[ ${PALAVRA[$n]} == "_" ]]; then
								printf " "
							else
								printf "${PALAVRA[$n]}"
							fi
						else
							printf "_"
							ACHOU=true
						fi
						let n++
					done

					#Ve se o jogo ja terminou
					if [[ $ACHOU = true ]]; then TERMINOU=false; else TERMINOU=true; break; fi
					printf "\n***********************************"

					printf "\n* Letras já tentadas: "
					for l in "${L_TENTATIVAS[@]}"; do printf "$l"; done
					printf "\n***********************************\n"

					cat "ascii_art/hang_$HANGMAN/$((7-$CHANCES))"

					printf "Escolha uma letra: "
					read -rsn1 LETRA

					#Algum bug com a letra 'a' minúscula
					if [[ $LETRA == "a" ]]; then
						LETRA="A"
					elif [[ $LETRA == "#" ]]; then
						break 3;
					fi
				done

				#Transforma em maiusculo
				LETRA=$(echo $LETRA | tr 'a-z' 'A-Z')
				ACHOU=false
				case "${L_TENTATIVAS[@]}" in  *"$LETRA"*) ACHOU=true; ;; esac

				if [[ $ACHOU = false ]]; then

					#Adciona letra à lista de ja tentadas
					L_TENTATIVAS[${#L_TENTATIVAS[@]}]=$LETRA

					#Verifica se letra existe na palavra à ser advinhada
					case "${FALTA_ADVINHAR[@]}" in  *"$LETRA"*) ACHOU=true; ;; esac

					if [[ "$ACHOU" = true ]]; then
						n=0;
						for l in "${FALTA_ADVINHAR[@]}"; do
							if [[ $l == $LETRA ]]; then
								FALTA_ADVINHAR[$n]=0
							fi
							let n++
						done
					else
						#Perdeu uma chance
						let CHANCES--
						if [[ $CHANCES == 0 ]]; then break; fi
					fi
				fi
			done

			clear

			if [[ $CHANCES -gt 0 ]]; then
				echo "*************"
				echo "* PARABÉNS! *"
				echo "*************"
			else
				echo "Você perdeu :("
			fi
			printf "A palavra era: "
			for u in "${PALAVRA[@]}"; do if [[ $u == "_" ]]; then printf " "; else printf $u; fi; done

			echo ". Você quer jogar novamente? [S/N]: "
			read -rsn1 op wasBack=true;
			if [[ "$op" != "S" ]] && [[ "$op" != "s" ]]; then break; fi
		done
	done
}

#Menu de ajuda:
if [[ $1 == "-help" ]]; then
	echo "Ajuda:"
	echo "Para criar uma nova categoria, crie um arquivo de texto com o nome da categoria na pasta hangman_categorias e coloque cada palavra em cada linha do arquivo"
	echo "Use -default para carregar as categorias default de teste."
	echo "Use -update para baixar o repositório atualizado do script, com novas categorias"

	echo "Build number:" $BUILD
	exit 0
fi

if [[ $1 == "-update" ]]; then
	echo "Aviso, isso limpará categorias criadas ou modificadas pelo usuário. Deseja continuar? [S/N]"
	read op
	if [[ "$op" == "S" ]] || [[ "$op" == "s" ]]; then
		get_update
	fi
	exit 0
fi

if [[ $1 == "-default" ]]; then
	load_default
fi

if [[ $1 == "-info" ]]; then
	info
fi

if [[ $1 == "-reload" ]]; then
	sort_levels
fi

setup

#MAIN LOOP
while [[ true ]]; do
	clear
	echo "************************************"
	echo "* - - - - - HANGMAN GAME - - - - - *"
	echo "************************************"
	echo "*  1. Novo Jogo                    *"
	echo "*  2. Configurações                *"
	echo "*  3. Ajuda                        *"
	echo "*  4. Sair                         *"
	echo "************************************"

	op=-1
	while [[ op -lt 1 ]] || [[ op -gt 4 ]]; do
		read -rsn1 op
	done

	case $op in
		1)
		{
			main_game
		}
		;;
		# Código imcompleto para fultura implementação de multiplos personagens //DESCONSIDERAR
		2)
		{
			settings
		}
		;;
		3)
		{
			help_
		}
		;;
		4) exit 0;;
	esac
done
