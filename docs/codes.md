# UART codes

Device is `/dev/ttySGK1`.
Direction `in` means read, `out` means write.

| Code | Direction | Name | Description |
|------|-----------|------|-------------|
| `FB 11 00 1C` | in | AlarmReport | Calling at door from the outside. Additional params: ch = 1 |
| `FB 23 00 2E` | in | CMD_STOP_RING 0x00 | Pick the call from physical intercom phone. Additional params: ch = 1 |
| `FB 13 00 1E` | in | HANG_UP 0x00 | Received when door times out without response (30 seconds) |
| `FB 10 04 1F` | out | CUart::Start | Initialize the hardware? Run at Sofia start. |
| `FB 16 00 21` | in | MCU_STATE 0x00 | unknown, appears after init |
| `FB 19 01 25` | in | PUSH_STATE 0x01 | unknown, apppears after init |
| `FB 10 00 1B` | out | unknown | Set after rebooting - CRecord::SetMode(2) |
| `FB 24 01 30` | in | CMD_DOWN_LONG 0x01 | Received every 5 minutes. |
| `FB 24 02 31` | in | CMD_DOWN_LONG 0x02 | Received every 5 minutes after previous one. |
| `FB 15 00 20` | out | CallGuard | Action to call guard. |
| `FB 15 03 23` | in | CallGuard_Error_2 | Guardian not available. |
| `FB 14 01 20` | out | StartStreamReader | Start a door call. Additional params. chn = 1, stream = 1 |
| `FB 14 01 20` | in | StartStreamReader | Received after call, success? |
| `FB 12 01 1E` | out | TRANSFER_CMD_UNLOCK_DOOR | Open the door, relay NO 1. |
| `FB 14 00 1F` | out | StopStreamReader | End intercom call. |
| `FB 17 01 23` | out | CallF1Func | Turn on relay F1 button. |
| `FB 17 00 22` | out | F1FuncOff | Turn off relay F1 button. |

Other unknown found:

```
SAVE_ADDR 0x%02x
CMD_RESET
STA_TO_AP
CMD_FACTORY_MODE 0x%02x
```
