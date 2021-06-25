# Storage

Board uses a 16MB flash memory with the following structure:

```
dev:    size   erasesize  name
mtd0: 00040000 00010000 "uboot"
mtd1: 00010000 00010000 "env"
mtd2: 001e0000 00010000 "kernel"
mtd3: 00230000 00010000 "rootfs"
mtd4: 00b10000 00010000 "usr"
mtd5: 00080000 00010000 "mnt"
mtd6: 00010000 00010000 "cfg"
```

- `mtd1` (env) and `mtd6` (cfg) contain plain data (string and binary).
- `mtd2`: Linux kernel ARM boot executable zImage (little-endian), xz compressed data 
- `mtd3`: Squashfs filesystem, little endian, version 4.0, compression:xz, size: 2227338 bytes, 505 inodes, blocksize: 65536 bytes
- `mtd4`: CramFS filesystem, little endian, size: 4108288, version 2, sorted_dirs, CRC 0x1CFD4679, edition 0, 1725 blocks, 105 files
- `mtd5`: JFFS2 filesystem, little endian

# Boot

During boot, `/etc/init.d/rcS` mounts the partitions and runs the main script,
which in turn loads all modules / drivers.

```
mount -t ramfs /dev/mem /var
mount -t cramfs /dev/mtdblock4 /usr
mount -t jffs2 /dev/mtdblock5 /mnt
echo /sbin/mdev > /proc/sys/kernel/hotplug
/usr/run.sh
```

If this fails to load, Wi-Fi won't work, and serial drops to a console without password request.

# Run script

Default script process is as follows:

- Enable `eth0 192.168.1.10` - may be reachable with board pins, didn't identify which ones.
- Run `telnetd`, which is both a security concern and the key to get into the board remotely.
- Create empty data folders in RamFS.
- Load module drivers, audio, media, and then other external drivers,
  a **Watchdog** `goke_wdt.ko`, the video decoder with OSD `BIT1628A`, and a touch driver.
- Copy web content (seems to be factory-removed) to Ram.
- Copy Wifi start scripts to Ram. Not executing at this point.
- Start `mdev -s`
- Copy "cloud states" and `npc_nts_client_config.ini`, which defines the cloud env to connect.
  This is stored in the persistent partition `/mnt` or copied if factory-reset.
- Copy `NVP6134C` audio codec firmware binary to `/tmp/sensor_hw.bin`.
- Extract compressed-LZMA `Sofia` program to Ram.
- Start `system_sofia` in background, which seems to provide some `telnetd` shell on `TCP/6683`. 
- Set system network `rmem_max` and `wmem_max` buffer to 1MB - buffer that receives UDP packets.
- Start and wait `e2prom_mac`, which seems to set MAC address on `eth0` (PducInfo) and few other settings,
  based in config `/dev/mtdblock6` and Uboot envs `/dev/mtdblock1`.
  It also does something with `/dev/watchdog` and may cause reboot.
- Link `resolv.conf` from persistent storage to Ram.
- Drop RAM cache, set kernel printk messages to emergency messages only (0).
- Run `interDebug /var/Sofia 9527`.

# Sofia

Sofia is the main program that controls the device and allows interaction with the user.
It exposes several ports:
- `TCP/34567`, management port, can be used locally by the application.
- `TCP/80` and `TCP/443`, used as a webserver to provide files and other uses (ONVIF-disabled).
  This service is inherited from other devices that do allow this.
- `UDP/5000`, allows to locate this device in the network (autodiscovery).
- `UDP/5002` - unknown.

During the running process, Sofia starts WiFi as follows:

- Load wireless module / driver `rtl8188fu.ko`, which was not loaded previously.
- Start script with `cd /var/wifi && sh go.sh`, which does
- Delete content and recreate folder `/var/run/wpa_supplicant`
- Kill all processes `hostapd udhcpd udhcpc wpa_supplicant`, wait 1 second
- Run `wpa_supplicant -i wlan0 -c /var/wifi/wpa_supplicant.conf -B`
- After this script finishes, decrypts internal Config, and sends Wireless credentials via
  `wpa_supplicant` socket, located in folder `/var/run/wpa_supplicant/wlan0`.
- When AP connection is established, runs DHCP to get an IP address with a custom script,
  `udhcpc -i wlan0 -s /var/wifi/udhcpc.conf`

Sofia also runs the following processes:

```
cd /usr/cloud/ && ./ntsclientcon_goke_static -E %s
```

## interDebug

So what's that `9527` variable set when launching Sofia?

As the program runs in background, we can't see the logs or interact with it.
If we provide a signal, we can enable the debug service and connect with it as `TCP/9527`.

```
kill -s SIGUSR1 `pgrep interDebug`
```

Then you can connect to the application with `ncat` from your computer.
It has an interactive console, so you can change some settings in here.
Also to be aware, this program allows to use a reverse `shell` to the device!

```
ncat wibox 9527
```

```
user name:admin
password:*****

19:50:38|trace login(admin, ******, Console, 0)
CUser::login admin

admin$help

-------------------------------------------------------------------
access      Print AccesssCtrl info
af          af [inner_command] [parameter], Example: af step 64
audio       audio: cmd [mod], mod = 0 line, 1 mic
audiogetg   audiogetg [line][mic] , Example: audiogetg line
audiogetv   audiogetv [line][mic] , Example: audiogetv line
audiosetg   audiosetg [line][mic] {num}, Example: audiosetg line 1
audiosetv   audiosetv [line][mic] {num} {num} {num} {num}, Example: audiosetv line 1 2 3 4
auth        auth control !
bitrate     Show the bit rate!
blc         BLC {1...} [{1~15}], Example: BLC 6
cam         Camera operation!
cpu         Dump the CPU usage!
defog       defog: cmd [mod], mod = 0 off, 1 auto, 2 manual
dn          test for day/night parameter:set day/night mode
ds          show day/night smartlight and wdr parameter:ds 0 or ds 1 or ds 2
dt          test for day/night smartlight and wdr parameter:
            eg:dt 1 1->set day wdr and smart light on
ef          test for day/night effect parameter
encode      to encode!
exit        sofia OnExit !
focus       Get Focus Info:  cmd
graphic     graphic debug !
help        Dump this help message!
isp         isp [inner_command] [parameter], Example: isp gain 100 100
mailsnap    mailsnap
motor       motor up/down/left/right !
nas         Tty mount nas:  cmd nasid
net         Net set!
net6        IPV6 Net set!
netUser     useronline!
packet      Dump packet infomation or packet!
part        Partition ide !
qrmake      QR Make: cmd [QR strings] [fullpath name]
quit        Logout myself!
qvprint     qvprint: cmd [mod] [loglevel]
re          reconfig all
reboot      Reboot the system!
rotate      rotate the video!(0~3)
shell       Entering system shell!
smartir     smartir {1...} [{1~15}], Example: smartir 6
smartlight   smartlight {1/0} [{10~999}], Example: smartlight 1
snap        to snap!
thread      Dump all thread!
time        Time operating!
timer       Dump all timer!
trans       Trans Printf!
vionoff     on(1) off(0)!
-------------------------------------------------------------------
To see details, please use `cmd -h`.
Test memory:help num(num: 1-10,(M))      example: help 9
```

## Autodiscover

By running a listen command and a broadcast command, we can check the devices available.
Identifier string is `ASZENO.SEARCH.V4.1`.

```
ncat -vlup 5001
---
echo -n "ASZENO.SEARCH.V4.1" | ncat -u 255.255.255.255 5000

ip: 403351744, netmask: 16777215, gateway: 16885952
<fanyun> Proc_msg_v4_Dev(1786) ExtNetCfg.DeviceDescription:IPCamera
GetVersion(120) version=V500.R001.A103.00.G0021.B007, 28
19:58:22|trace CAutoSearch::ThreadProc():send ack msg 1861 , buf_len ==> 616
ezio send to wlan0
```
