# Fermax Wi-Box

This repository contains hardware and software information from [Fermax Wi-Box] device,
and contains custom scripts and files to patch and use the device locally,
instead of using Chinese cloud.

[Fermax Wi-Box]: https://www.fermax.com/spain/single-products/f03266-desvio-de-llamada-wifi-vds-wi-box

- [x] Disable Sofia (original program) at boot, can be re-enabled
- [x] Allow to modify root password
- [x] Open door remotely via HTTP and MQTT
- [x] Integrate with Home Assistant (MQTT)
- [ ] Use intercom audio
- [x] Build toolset to compile other software
- [x] Use dropbear SSH

This has been tested with following firmware versions:
- `V500.R001.A103.00.G0021.B007`
- `V500.R001.A103.00.G0021.B013`

# Requirements

This project uses [cramfs-tools] to extract and build the userdata image.

[cramfs-tools]: https://github.com/npitre/cramfs-tools

# Install

Check [INSTALL](./INSTALL.md) document for complete information.

Use `sudo make all` to run all the steps to prepare your custom image.

You can manually extract and build your image:

```
sudo cramfsck -x /tmp/cram mtd4-file
sudo mkcramfs -e 0 -v -L /tmp/cram/ /tmp/cramfs.file
```

# Related

Some content is provided from the following sources:

- [https://linuch.pl/blog/fermax-wayfi-wideodomofon-hack-czesc-1](https://web.archive.org/web/20211121234612/https://linuch.pl/blog/fermax-wayfi-wideodomofon-hack-czesc-1)  
- [https://linuch.pl/blog/fermax-wayfi-wideodomofon-hack-czesc-2](https://web.archive.org/web/20211124125931/https://linuch.pl/blog/fermax-wayfi-wideodomofon-hack-czesc-2) 
- [https://linuch.pl/blog/fermax-wayfi-wideodomofon-hack-czesc-3](https://web.archive.org/web/20211124125929/https://linuch.pl/blog/chinska-kamera-ip-blk510-i-reverse-engineering) 

# Disclaimer

YOU are responsible for any use or damage this software may cause.
This repo and its content is intended for educational and research purposes only.
Use at your own risk.
