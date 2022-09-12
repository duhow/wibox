# UART codes

Device is `/dev/ttySGK1`.
Direction `in` means read, `out` means write.

All codes start with hex `FB` and end with a CRC code. Sofia app outputs it as `uCrc` with two integer values.
`uCrc` output value is sum of all bytes, and sum of 11 (`xB`) and the data values.

Given code `FB 20 00`, CRC last value = `B + 20 + 00` = `0x2B`.
`uCrc = 326, 43`

| Code | Direction | Name | Description |
|------|-----------|------|-------------|
| `FB 00 00 FF` | in | unknown | Unknown, appeared after closing call. |
| `FB 10 00 1B` | out | unknown | Set after rebooting - CRecord::SetMode(2) |
| `FB 10 04 1F` | out | CUart::Start | Initialize the hardware? Run at Sofia start. |
| `FB 10 5E 79` | out | Unknown | Unknown. Appears after init. |
| `FB 11 00 1C` | in | AlarmReport | Calling at door from the outside. Additional params: ch = 1 |
| `FB 12 01 1E` | out | TRANSFER_CMD_UNLOCK_DOOR | Open the door, relay NO 1. |
| `FB 13 00 1E` | in | HANG_UP 0x00 | Received when door times out without response (30 seconds) |
| `FB 13 01 1F` | in | HANG_UP 0x01 | Received when opening door / StartStreamReader? |
| `FB 14 00 1F` | out | StopStreamReader | End intercom call. |
| `FB 14 01 20` | in/out | StartStreamReader | Start a door call. Received after call, success? Additional params. chn = 1, stream = 1 |
| `FB 15 00 20` | out | CallGuard | Action to call guard. |
| `FB 15 03 23` | in | CallGuard_Error_2 | Guardian not available. |
| `FB 16 00 21` | in | MCU_STATE 0x00 | unknown, appears after init |
| `FB 16 01 22` | in | MCU_STATE 0x01 | After clicking button P2 (reset). LED blinks to red. |
| `FB 17 00 22` | out | F1FuncOff | Turn off relay F1 button. |
| `FB 17 01 23` | out | CallF1Func | Turn on relay F1 button. |
| `FB 18 04 27` | in | SAVE_ADDR 0x04 | Appears after configuring with button P2 and pressing the intercom button. |
| `FB 18 5E 81` | in | SAVE_ADDR 0x5e | Unknown. Appears after init. |
| `FB 19 00 24` | in/out | PUSH_STATE 0x00 | Wifi/calls are disabled. Can be set. |
| `FB 19 01 25` | in/out | PUSH_STATE 0x01 | Wifi/calls are enabled. Can be set. |
| `FB 20 00 2B` | in | CMD_RESET | After clicking button P1 (wifi) 5 times. Triggers Sofia to delete wifi and reboot. |
| `FB 21 00 2C` | in | STA_TO_AP | After pressing for +5s the button, triggers Sofia to reboot and start in AP mode. |
| `FB 23 00 2E` | in | CMD_STOP_RING 0x00 | Pick the call from physical intercom phone. Additional params: ch = 1 |
| `FB 24 01 30` | in | CMD_DOWN_LONG 0x01 | Received every 5 minutes. |
| `FB 24 02 31` | in | CMD_DOWN_LONG 0x02 | Received every 5 minutes after previous one. |

Other unknown found:

```
CMD_FACTORY_MODE 0x%02x
```
