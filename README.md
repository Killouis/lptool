# Lptool

Lptool is a simple bash script that interrogate Lastpass vault using Lastpass CLI (lpass) commands.

## Getting Started

This tool is used to view, copy and print password from LastPass user.

### Installing

To install lptool you need to download repo, go to downloaded folder and install .deb file with the following command:

```
sudo dpkg -i lptool.deb
```

Next run lptool with installation option:

```
lptool -i
```

And to login with you email of Lastpass, use this command:

```
lptool email@domain.com
```

## Options

Lptool accepts the following command line options:

```
-p <project_name>
  Project name to match for your research

-k <key>
  Keywords to look for in your password vault

-c
  Automatically copy the password in your system clipboard when the research finds only one result.

-s
  Automatically print the password when the research finds only one result.

-h
  Show help menu
  
-i
  Install this tool's dependencies
```

## Built With

* [lpass_cli](https://github.com/lastpass/lastpass-cli) - Lastpass CLI

## Authors

* **Lorenzo Verardo**
