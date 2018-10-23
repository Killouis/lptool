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
    echo -e "Usage: lptool [-p <project_name>] [-k <ID>] [-c/-s] [-h] [-i]\n
  -p <project_name>\tProject name to match for your research
  -k <ID>\t\tKeywords to look for in your password vault
  -c\t\t\tAutomatically copy the password in your system clipboard  when  the research finds only one result
  -s\t\t\tAutomatically  prints the password when the research finds only one result
  -h\t\t\tShow this description
  -i\t\t\tInstall this tool's dependencies\n
Please see also the documentation at https://github.com/killouis/lptool." 1>&2
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
      	echo -e "\nMissing requirements: lpass has not been installed correctly."
      else
      	echo -e "\nInstallation of requirement is done. Run the following command with your mail address to configure LastPass on your device:\n\nlptool email@domain.com"
        sudo touch /opt/lptool/config
      fi
    else
      echo -e "The installation is not required.\nTo force the installation, delete this file /opt/lptool/config."
    fi
    exit 1
    ;;
 *)
    echo -e "Usage: lptool [-p <project_name>] [-k <ID>] [-c/-s] [-h] [-i]\n
  -p <project_name>\tProject name to match for your research
  -k <ID>\t\tKeywords to look for in your password vault
  -c\t\t\tAutomatically copy the password in your system clipboard  when  the research finds only one result
  -s\t\t\tAutomatically  prints the password when the research finds only one result
  -h\t\t\tShow this description
  -i\t\t\tInstall this tool's dependencies\n
Please see also the documentation at https://github.com/killouis/lptool." 1>&2
   exit 1
   ;;
 esac
done
loop=1;
while [[ $loop -eq 1 ]]; do
  lpass --version | grep "LastPass CLI" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Missing requirements: lpass has not been installed correctly.\nRun the installation with command:\n\nlptool -i."
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
      echo -e "To login use the following command with your email address.\nExample:\n\tlptool email@domain.com".
      break
    fi
  else
    if [ "$print" = true ]; then
      lpass show $(eval "echo $key") | head -3 | tail -1 | cut -d ' ' -f2-
      break
    fi
    echo -e "\e[92m$(lpass status)\033[0m\n"
    if [ ${#key[@]} -eq 0 ]; then
      echo -e "Usage: lptool [-p <project_name>] [-k <ID>] [-c/-s] [-h] [-i]\n" 1>&2
      if [ ${#project[@]} -ne 0 ]; then
        echo -e "Project Name:" $project_name "\n"
      fi
      read -p "What do you want to find? " -a search -e
      echo -e
      if [ -z $search ]; then
        search="\"\""
      fi
    else
      echo -e "ID:" $key "\n"
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
        echo -e "Password on clipboard!\n"
        break
      fi
    elif [ $count = 0 ]; then
      echo -e "Result not found!\n"
      read -e -p "Retry? (Y/n) " retry
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
        echo -e "Multiple value. Cannot copy.\n"
      fi
      for (( c=1; c<=$count; c++ ))
      do
        trap "break" 2
        echo "$c)" $(eval "lpass ls $grep_string | grep -i ${search[$i]} | head -$c | tail -1 | head -c-26")
      done
      trap - 2
      echo -e
      read -e -p "Choose a key (Default 1): " number
      echo -e
      if [ -z $number ]; then
        number=1
      fi
    fi
    if [ "$number" -ge 1 -a "$number" -le $count ]; then
      lpass show $(eval "lpass ls $grep_string | grep -i ${search[$i]} | head -$number | tail -1 | awk '{print $NF}' | grep -o '[0-9]\+'")
      echo -e
      read -e -p "Do you want copy password? (Y/n) " copy
      case $copy in
        [yY][eE][sS]|[yY]|'')
          lpass show -cp $(eval "lpass ls $grep_string | grep -i ${search[$i]} | head -$number | tail -1 | awk '{print $NF}' | grep -o '[0-9]\+'")
          echo Copied
          ;;
        *)
          echo Not copied
          ;;
      esac
    else
      echo Value is not valid
    fi
  fi
  read -e -p "Retry? (N/y) " retry
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
