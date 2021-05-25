# R-Link Evolution Missing Explorer 🚘

[![Donate with PayPal](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=P3DGL6EANDY96&source=url)
[![License BSD 3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](LICENSE)
[![Follow JV conseil – Internet Consulting on Twitter](https://img.shields.io/twitter/follow/JVconseil.svg?style=social&logo=twitter)](https://twitter.com/JVconseil)

A shell script to mount TOMTOM.xxx files from a TomTom SD card, to browse/modify its content.

## Usage

Place `rlink.sh` file in the same folder where your TOMTOM.000 ... files are, ideally on the SD card:

```bash
/Volumes/SDCARD
├── TOMTOM.000
├── TOMTOM.001
├── TOMTOM.002
├── TOMTOM.003
└── rlink.sh
```

To start assembling your TOMTOM.xxx files enter the following line in Terminal on Ubuntu:

```bash
bash ./rlink.sh
````

In case VirtualBox does not recognize your SD card on your Mac, you may want to use `virtualbox.sh` command lines by sourcing them first:

```bash
source "$HOME/virtualbox.sh"
```

then call `vbox` command to follow the procedure to link your SD card to your Ubuntu VM on VirtualBox.

## Requirements

- VirtualBox is a powerful x86 and AMD64/Intel64 virtualization product for enterprise as well as home use:
https://www.virtualbox.org
- VirtualBox 6.1.22 Oracle VM VirtualBox Extension Pack:
https://www.virtualbox.org/wiki/Downloads
- Ubuntu Desktop 20.04.2.0 LTS (LTS stands for long-term support — which means five years, until April 2025, of free security and maintenance updates, guaranteed):
https://ubuntu.com/download/desktop

## Example

![R-Link Evolution Missing Explorer on Ubuntu through VirtualBox VW on Mac](https://user-images.githubusercontent.com/8126807/119517690-20443c00-bd78-11eb-9b78-1933cf93d576.png)
R-Link Evolution Missing Explorer on Ubuntu through VirtualBox VW on Mac.
