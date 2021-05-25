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

## Requirements

- VirtualBox is a powerful x86 and AMD64/Intel64 virtualization product for enterprise as well as home use: https://www.virtualbox.org
- Ubuntu Desktop 20.04.2.0 LTS (LTS stands for long-term support — which means five years, until April 2025, of free security and maintenance updates, guaranteed): https://ubuntu.com/download/desktop
