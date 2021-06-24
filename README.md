# Fermax Wi-Box

This repository contains hardware and software information from [Fermax Wi-Box] device,
and contains custom scripts and files to patch and use the device locally,
instead of using Chinese cloud.

[Fermax Wi-Box]: https://www.fermax.com/spain/pro/productos/videoporteros/monitores/SF-91-monitor-veo/PR-13598-desvio-de-llamada-wifi-vds-wibox.html

Full functionality is not available, at the moment it can open the door remotely,
and alert when someone rings at the door. (TODO)

This has been tested with firmware `V500.R001.A103.00.G0021.B007`.

# Requirements

This project uses [cramfs-tools] to extract and build the userdata image.

[cramfs-tools]: https://github.com/npitre/cramfs-tools

# Install

You can extract and build your image:

```
sudo cramfsck -x /tmp/cram mtd4-file
sudo mkcramfs -e 0 -v -L /tmp/cram/ /tmp/cramfs.file
```

# Related

Some content is provided from the following sources:

https://linuch.pl/blog/fermax-wayfi-wideodomofon-hack-czesc-1  
https://linuch.pl/blog/fermax-wayfi-wideodomofon-hack-czesc-2  
https://linuch.pl/blog/fermax-wayfi-wideodomofon-hack-czesc-3  

# Disclaimer

YOU are responsible for any use or damage this software may cause.
This repo and its content is intended for educational and research purposes only.
Use at your own risk.
