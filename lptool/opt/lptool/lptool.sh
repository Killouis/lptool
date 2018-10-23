#! /bin/bash
while getopts ":p:k:c :s :h :i" option; do
 case "${option}" in
 p)
    read -r -a project <<< "Shared-Quantyca_Projects/Projects\\\\\\\\$OPTARG"
    read -r -a project_name <<< "$OPTARG"
    ;;
 k)
    read -r -a key <<< "$OPTARG"
    ;;
 c)
    clipboard=true
    ;;
 s)
    print=true
    ;;
 h)
    echo -e "Usage:
    \t lptool [-p <nomeprogetto>] [-k <chiave>] [-c/-s] [-h] [-i]\n
    \t-p <nomeprogetto>
    \t    Nome del progetto in cui effettuare la ricerca
    \t-k <chiave>
    \t    Chiave di ricerca
    \t-c
    \t    Copia direttamente la password nella clipboard se viene matchato un solo risultato.
    \t-s
    \t    Stampa direttamente la password se viene matchato un solo risultato.
    \t-h
    \t    Mostra questa descrizione.
    \t-i
    \t    Installa il tool e le dipendenze.
    " 1>&2
    exit 1
    ;;
i)
    if [ ! -f /opt/lptool/config ]; then
      sudo apt-get install openssl libcurl4-openssl-dev libxml2 libssl1.0-dev libxml2-dev pinentry-curses xclip cmake build-essential pkg-config git
      sudo rm -rf /opt/lptool/lastpass-cli
      sudo git clone https://github.com/lastpass/lastpass-cli.git /opt/lptool/lastpass-cli
      cd /opt/lptool/lastpass-cli
      sudo make
      sudo make install
      cd -
      sudo rm -rf /opt/lptool/lastpass-cli
      lpass --version | grep "LastPass CLI" > /dev/null 2>&1
      if [ $? -ne 0 ]; then
      	echo -e "\nPrerequisti mancanti: lpass non è stato installato correttamente."
      else
      	echo -e "\nInstallazione dei prerequisiti completata. Eseguire seguente comando con la propria mail per configurare LastPass sul dispositivo:\n\nlptool email@domain.com"
        sudo touch /opt/lptool/config
      fi
    else
      echo -e "Installazione non necessaria.\nPer forzare l'installazione cancellare il file /opt/lptool/config."
    fi
    exit 1
    ;;
 *)
   echo -e "Usage:
   \t lptool [-p <nomeprogetto>] [-k <chiave>] [-c/-s] [-h] [-i]\n
   \t-p <nomeprogetto>
   \t    Nome del progetto in cui effettuare la ricerca
   \t-k <chiave>
   \t    Chiave di ricerca
   \t-c
   \t    Copia direttamente la password nella clipboard se viene matchato un solo risultato.
   \t-s
   \t    Stampa direttamente la password se viene matchato un solo risultato.
   \t-h
   \t    Mostra questa descrizione.
   \t-i
   \t    Installa il tool e le dipendenze.
   " 1>&2
   exit 1
   ;;
 esac
done
loop=1;
while [[ $loop -eq 1 ]]; do
  lpass --version | grep "LastPass CLI" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Prerequisti mancanti: lpass non è stato installato correttamente.\nEseguire l'installazione con il comando:\n\nlptool -i."
    break
  fi
  if [ "$print" != true ]; then
    clear
  fi
  lpass ls > /dev/null 2>&1
  if [ "$(lpass status)" = "Not logged in." ]; then
    if [ "$1" ]; then
      lpass login $1
    else
      echo -e "\e[91m$(lpass status)\033[0m"
      echo -e "Passare come argomento la mail per effettuare il login.\nExample:\n\tlptool email@domain.com".
      break
    fi
  else
    if [ "$print" = true ]; then
      lpass show $(eval "echo $key") | head -3 | tail -1 | cut -d ' ' -f2-
      break
    fi
    echo -e "\e[92m$(lpass status)\033[0m\n"
    if [ ${#key[@]} -eq 0 ]; then
      echo -e "Usage: lptool [-p <nomeprogetto>] [-k <chiave>] [-c/-s] [-h] [-i]\n" 1>&2
      if [ ${#project[@]} -ne 0 ]; then
        echo -e "Progetto:" $project_name "\n"
      fi
      read -p "Cosa cerchi? " -a search -e
      echo -e
      if [ -z $search ]; then
        search="\"\""
      fi
    else
      echo -e "Chiave di ricerca:" $key "\n"
      search=("${key[@]}")
    fi
    if [ ${#project[@]} -ne 0 ]; then
      grep_string=(" | grep -i ${project[@]}")
    fi
    for (( i=0; i<${#search[@]}-1; i++ ))
    do
      grep_string="$grep_string | grep -i ${search[$i]}"
    done
    count=$(eval "lpass ls $grep_string | grep -ic ${search[$i]}")
    if [ $count = 1 ]; then
      number=1
      if [ "$clipboard" = true ]; then
        lpass show -cp $(eval "echo $key")
        echo -e "Password copiata!\n"
        break
      fi
    elif [ $count = 0 ]; then
      echo -e "Nessun risultato trovato\n"
      read -e -p "Riprovare? (Y/n) " retry
      case $retry in
        [yY][eE][sS]|[yY]|'')
          continue
          ;;
        *)
          break
          ;;
      esac
    else
      if [ "$clipboard" = true ]; then
        echo -e "Valori multipli. Copia non effettuata.\n"
      fi
      for (( c=1; c<=$count; c++ ))
      do
        trap "break" 2
        echo "$c)" $(eval "lpass ls $grep_string | grep -i ${search[$i]} | head -$c | tail -1 | head -c-26")
      done
      trap - 2
      echo -e
      read -e -p "Scegli un elemento (Default 1): " number
      echo -e
      if [ -z $number ]; then
        number=1
      fi
    fi
    if [ "$number" -ge 1 -a "$number" -le $count ]; then
      lpass show $(eval "lpass ls $grep_string | grep -i ${search[$i]} | head -$number | tail -1 | awk '{print $NF}' | grep -o '[0-9]\+'")
      echo -e
      read -e -p "Copiare la password? (Y/n) " copy
      case $copy in
        [yY][eE][sS]|[yY]|'')
          lpass show -cp $(eval "lpass ls $grep_string | grep -i ${search[$i]} | head -$number | tail -1 | awk '{print $NF}' | grep -o '[0-9]\+'")
          echo Copiata
          ;;
        *)
          echo Non copiata
          ;;
      esac
    else
      echo Valore non valido
    fi
  fi
  read -e -p "Riprovare? (N/y) " retry
  case $retry in
    [yY][eE][sS]|[yY])
      continue
      ;;
    [nN][oO]|[nN]|'')
      break
      ;;
    *)
      break
      ;;
  esac
done
