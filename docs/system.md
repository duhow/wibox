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

Sofia will also check file `/var/cloud/states` managed by NTS Cloud process, and ensure status is "connected":

```
[STATE]
ConnState=2
FailCode=0
```

## system_sofia

In order to run some commands, there's an additional process called `system_sofia`.
This process exposes port `TCP/6683` which allows to run commands with `system` C function.

Code is somewhat protected to only allow connections from `127.0.0.XXX`, so even if a user sends
a valid payload, an error string will appear to the application and not allow to run the command.

Packets have a fixed length of **1032** bytes with padded `NULL` characters.
Magic string is `xV4\x12`.

A simple Python script to craft packages would be:

```python
import sys

VAR_LOG = [b"\x01", b"\x02"]
MAGIC_STR = b'xV4\x12'

log = True

PACKET = MAGIC_STR + VAR_LOG[int(log)] + (b"\0"*3) + bytes(" ".join(sys.argv[1:]), "utf-8")
PACKET += b'\x00' * (1032 - len(PACKET))

sys.stdout.buffer.write(PACKET)
```

Some of the commands run by **Sofia** are:

```
rm /var/Sofia
ip -6 addr del 2001:0db8:0:f101::a/64 dev eth0
ip -6 addr add 2001:0db8:0:f101::a/64 dev eth0
umount -l /var/fat32_0
mkdir -p /var/fat32_0
killall ntsclientcon_goke_static
echo 3 > /proc/sys/vm/drop_caches
cd /usr/cloud/ && ./ntsclientcon_goke_static -E ${m_dVerifyCode}
sed -ri 's/(ssid=).*/\\1IDS7938${SERIAL_NUMBER_4}/' /var/wifi/hostapd.conf
sed -ri 's/(wpa_passphrase=).*/\\1${UDID_SN}/' /var/wifi/hostapd.conf
insmod /ko/extdrv/rtl8188fu.ko
ifconfig eth0 down
cd /var/wifi && sh go.sh
```

## NTS Client

This is a Cloud agent which acts between Cloud and device local port `TCP/34567`.
It also opens a random port locally.
Requires to have a Verify Code `AuthPwd`, can be provided when launching program with `-E` param.
`DevId` is already set from the config file in persistent storage.

```
TDK_SR_StartService ....
[Prompt]  Start service.......
[Prompt]  Little-endian!
[Prompt]  AdapterName: eth0, Ip: 192.168.1.10.
[Prompt]  AdapterName: wlan0, Ip: 192.168.10.24.
[Prompt]  LocalIpaddr: 192.168.1.10.
[Prompt]  LocalIpaddr: 192.168.10.24.
[Prompt]  v2.4.1.12
[Log]  [NETCOM] <Mode[NETCOM]> <Ver[1.0.1.2 2134]> .
[Prompt]  Start service complete!
[Prompt]  Start test server......
[Prompt]  Test server success.
[Prompt]  Server udp ip[47.254.155.166], port[8300]; https ip[47.254.155.166], port[443].
[Prompt]  Start network detection.
[Prompt]  The current number of connections: 0.
[Prompt]  Detection of network end.
[Prompt]  Nat check over, Nat type: Port Rest cone nat, public ip: 1.2.3.4:38630.
[Prompt]  Starting login authentication server.
[Prompt]  [NETCOM] HttpCli ==> connect addr 47.254.155.166, port 443  ==> fd 7  nRet[1]
[Prompt]  [NETCOM] HttpCli ==> connect addr 47.254.155.166, port 443  ==> fd 8  nRet[1]
[Prompt]  Connection authentication server successfully.
[Prompt]  Login authentication server sends a request message.
[Prompt]  Device is registered to the auth server success.
[Prompt]  Active resp msg: Public addr: 1.2.3.4:51392, RTT: 1000757ms.
[Prompt]  The current number of connections: 0.
[Prompt]  The current number of connections: 0.
[Prompt]  The current number of connections: 0.
[Prompt]  The current number of connections: 0.
[Prompt]  Request to establish a P2P connection.
[Prompt]  Create logical TCP connection request.
[Prompt]  Connecting devices results event, connecting results: success.
[Prompt]  Open the connection to the end.
[Prompt]  Create logical TCP connection request.
[Prompt]  Connecting devices results event, connecting results: success.
[Prompt]  The current number of connections: 1.
[Prompt]  Open the connection to the end.
[Prompt]  Active resp msg: Public addr: 1.2.3.4:38600, RTT: 1526900ms.
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
