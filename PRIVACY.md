# Privacy Policy

**Mini Calendar collects nothing and sends nothing about you. It opens no
network connection at all unless you switch on public holidays, and then it
only downloads public holiday lists.**

There is no analytics, no crash reporting, no telemetry, no account, no
"anonymous usage statistics", and no third-party SDK of any kind. The app draws
a calendar from your Mac's system clock; lunar dates and solar terms are
computed on your Mac.

Last updated: 19 September 2026. Applies to Mini Calendar 1.1.0 and later.

## What the app stores

Nine preferences, written by macOS to a plain file on your own Mac:

```
~/Library/Preferences/me.mynaturefriends.mcalendar.plist
```

They are: number of months shown, show date in the menu bar, show weekday in the
menu bar, show week numbers, show lunar dates, show holidays, which countries'
holidays to show, interface language, and appearance. That is the complete
list.

With holidays on and China selected, the downloaded Chinese holiday schedules
are cached in `~/Library/Caches/me.mynaturefriends.mcalendar/ChinaHolidays/`.

If you turn on **Launch at login**, the app registers itself with macOS as a
login item (via `SMAppService`). That registration lives in the system, not in
the app, and turning the switch off removes it.

Deleting `mCalendar.app`, the file above and that cache folder removes every
trace of the app.

## Holidays: the only network access

Public holidays are **off by default**. While they are off, the app makes no
network request of any kind. Lunar dates and solar terms never use the network.

When you turn holidays on in Settings, the app downloads public holiday lists,
and nothing else, from the addresses below. All requests are HTTPS `GET`
requests with no request body.

| Used for | Exact URL | Service |
| --- | --- | --- |
| Holidays in Finland, Estonia, the US and Kazakhstan | `https://date.nager.at/api/v3/PublicHolidays/{year}/{country}` | [Nager.Date](https://date.nager.at), a free public holiday API |
| China's holidays and make-up workdays | `https://raw.githubusercontent.com/NateScarlet/holiday-cn/master/{year}.json` | [holiday-cn](https://github.com/NateScarlet/holiday-cn) on GitHub, an open-source copy of the State Council notices |
| The same file, only if GitHub cannot be reached | `https://cdn.jsdelivr.net/gh/NateScarlet/holiday-cn@master/{year}.json` | jsDelivr CDN mirror of the above |

`{country}` is the two-letter code of a country you ticked (`FI`, `EE`, `US`
or `KZ`). `{year}` is a year on screen, or the year either side of it
(for example `2026`).

When downloads happen:

- Only when the calendar popover is open, and only for the countries you
  ticked.
- Nager.Date: at most once a day per country and year. The result is kept in
  memory only and forgotten when the app quits.
- China: saved to the cache folder above. A past year is never downloaded
  again. The current and later years are checked at most once a day, because
  the schedule is sometimes revised. The 2025 and 2026 schedules are built into
  the app, so they show even with no connection.

### What a request contains

This is the complete request the app sends, for example:

```
GET /api/v3/PublicHolidays/2026/FI HTTP/1.1
Host: date.nager.at
Accept: */*
Accept-Language: en
Accept-Encoding: gzip, deflate
User-Agent: MiniCalendar
```

- The `User-Agent` and `Accept-Language` headers are fixed values set by the
  app. They are the same for every user and do not reveal your macOS version,
  your language or the app's version.
- No cookies are sent or stored. The app keeps no web cache.
- No identifier, account, device name, serial number, location, time zone or
  any of your settings are sent. The only information in the request is what
  you can see in the URL: a year, and for Nager.Date the code of a country you
  ticked.

### What is never sent

- Nothing about you or your Mac, and nothing about how you use the app.
- Nothing is uploaded: the app never sends a `POST` or any request with a body.
- No analytics, crash reports, update checks or "phone home" of any kind.

Like any connection on the internet, the servers above can see your IP address
and the time of the request. Their own privacy policies cover what they do with
it: [Nager.Date](https://date.nager.at/legal/privacy),
[GitHub](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement),
[jsDelivr](https://www.jsdelivr.com/terms/privacy-policy-jsdelivr-net).
To avoid this entirely, leave holidays off.

## What the app never touches

- **The network, beyond the holiday downloads listed above.**
- **Your calendars, events, reminders, or contacts** — Mini Calendar has no
  events feature and does not use EventKit. It never asks for those permissions,
  because it has no use for them.
- **Your files, photos, microphone, camera, or location.**
- **Your keystrokes or screen.** The app has no accessibility or screen-recording
  permissions.

Mini Calendar requests no system permissions at all, so macOS never shows you a
consent prompt for it.

## Verifying this yourself

You do not have to take my word for it:

- The full source is at
  <https://github.com/javaidea/mCalendar> — it is about 1,800 lines. All
  network code is in `Sources/mCalendar/Holidays/`, and every request goes
  through the one session defined in `HolidaySession.swift`.
- `codesign -d --entitlements - /Applications/mCalendar.app` shows the app
  requests no entitlements.
- Point a network monitor (Little Snitch, LuLu, `nettop`) at it: with holidays
  off it stays silent; with them on, it contacts only `date.nager.at`,
  `raw.githubusercontent.com` and, as a fallback, `cdn.jsdelivr.net`.

## Distribution

Releases are signed with an Apple Developer ID certificate and notarized by
Apple, so macOS can verify the download has not been tampered with. Download only
from the [Releases page](https://github.com/javaidea/mCalendar/releases).

## Changes

If this policy ever changes it will be in this file, in the repository's history,
where you can see exactly what changed and when. It last changed when holidays were
added, the first feature that uses the network.

## Contact

Questions: open an issue at
<https://github.com/javaidea/mCalendar/issues>.

---

# 隐私政策

**Mini Calendar 不收集、不发送任何关于你的信息。除非你打开"显示节假日",它不会建立
任何网络连接;打开后也只下载公开的节假日列表。**

没有统计分析,没有崩溃上报,没有遥测,不需要账号,没有所谓"匿名使用数据",也没有
任何第三方 SDK。它读取你 Mac 的系统时间画出一张日历;农历和节气都在本机计算。

最后更新:2026年9月19日。适用于 Mini Calendar 1.1.0 及之后的版本。

## 应用保存了什么

九项设置,由 macOS 写在你自己电脑上的一个普通文件里:

```
~/Library/Preferences/me.mynaturefriends.mcalendar.plist
```

分别是:显示月份数、菜单栏是否显示日期、菜单栏是否显示星期、是否显示周数列、
是否显示农历、是否显示节假日、显示哪些国家的节假日、界面语言、外观。全部内容就这些。

打开节假日并勾选中国时,下载的中国放假安排会缓存在
`~/Library/Caches/me.mynaturefriends.mcalendar/ChinaHolidays/`。

如果你打开**开机自动启动**,应用会通过 `SMAppService` 向 macOS 注册为登录项。
这条注册记录保存在系统里,不在应用内,关掉开关即被移除。

删除 `mCalendar.app`、上面那个文件和这个缓存目录,应用就不会在你的电脑上留下任何痕迹。

## 节假日:唯一的联网功能

节假日**默认关闭**。关闭时,应用不发出任何网络请求。农历和节气功能从不联网。

在设置中打开节假日后,应用只会从下面这几个地址下载公开的节假日列表,不做别的事。
所有请求都是 HTTPS `GET` 请求,没有请求体。

| 用途 | 完整 URL | 服务 |
| --- | --- | --- |
| 芬兰、爱沙尼亚、美国、哈萨克斯坦的节假日 | `https://date.nager.at/api/v3/PublicHolidays/{年份}/{国家}` | [Nager.Date](https://date.nager.at),免费的公共假日 API |
| 中国的放假和调休安排 | `https://raw.githubusercontent.com/NateScarlet/holiday-cn/master/{年份}.json` | GitHub 上的开源项目 [holiday-cn](https://github.com/NateScarlet/holiday-cn),整理自国务院公告 |
| 同一个文件,仅在连不上 GitHub 时使用 | `https://cdn.jsdelivr.net/gh/NateScarlet/holiday-cn@master/{年份}.json` | 上一项在 jsDelivr CDN 上的镜像 |

`{国家}` 是你勾选的国家的两位代码(`FI`、`EE`、`US` 或 `KZ`)。`{年份}` 是
日历上显示的年份,或它前后各一年(例如 `2026`)。

什么时候下载:

- 只在日历弹窗打开时,只下载你勾选的国家。
- Nager.Date:每个国家每个年份最多每天下载一次。结果只保存在内存里,退出应用即清除。
- 中国:保存在上面提到的缓存目录中。过去的年份不会再次下载;当年及以后的年份
  最多每天检查一次,因为放假安排偶尔会调整。2025、2026 年的安排已内置在应用里,
  没有网络也能显示。

### 请求里包含什么

以下就是应用发出的完整请求,例如:

```
GET /api/v3/PublicHolidays/2026/FI HTTP/1.1
Host: date.nager.at
Accept: */*
Accept-Language: en
Accept-Encoding: gzip, deflate
User-Agent: MiniCalendar
```

- `User-Agent` 和 `Accept-Language` 是应用设定的固定值,所有用户都一样,不会透露
  你的 macOS 版本、系统语言或应用版本。
- 不发送也不保存任何 Cookie,应用不保留网页缓存。
- 不发送任何标识符、账号、设备名、序列号、位置、时区或你的任何设置。请求里的全部
  信息就是 URL 里能看到的:一个年份,以及(Nager.Date 请求中)你勾选的一个国家代码。

### 绝不会发送什么

- 任何关于你或你的 Mac 的信息,以及你如何使用本应用的信息。
- 不上传任何内容:应用从不发送 `POST` 请求,也不发送任何带请求体的请求。
- 没有统计、崩溃上报、更新检查,或任何形式的"回传"。

和互联网上的任何连接一样,上面这些服务器能看到你的 IP 地址和请求时间。它们如何
处理这些信息,由各自的隐私政策说明:[Nager.Date](https://date.nager.at/legal/privacy)、
[GitHub](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement)、
[jsDelivr](https://www.jsdelivr.com/terms/privacy-policy-jsdelivr-net)。
如果不想有任何连接,保持节假日关闭即可。

## 应用绝不接触什么

- **上面列出的节假日下载以外的任何网络连接。**
- **你的日历、日程、提醒事项、通讯录**——本应用没有日程功能,不使用 EventKit,
  也从不申请这些权限,因为它用不上。
- **你的文件、照片、麦克风、摄像头、位置。**
- **你的按键和屏幕内容**——应用没有辅助功能权限,也没有屏幕录制权限。

Mini Calendar 不申请任何系统权限,所以 macOS 从不会为它弹出授权请求。

## 你可以自己验证

这些话不必只听我说:

- 完整源码在 <https://github.com/javaidea/mCalendar>,大约 1800 行,
  所有联网代码都在 `Sources/mCalendar/Holidays/` 目录下,每个请求都经由
  `HolidaySession.swift` 中定义的同一个网络会话发出。
- `codesign -d --entitlements - /Applications/mCalendar.app` 会显示它没有申请
  任何 entitlement。
- 用网络监控工具(Little Snitch、LuLu、`nettop`)盯着它:关闭节假日时它一直静默;
  打开后它只访问 `date.nager.at`、`raw.githubusercontent.com`,以及备用的
  `cdn.jsdelivr.net`。

## 分发方式

发布版本使用 Apple Developer ID 证书签名并已通过 Apple 公证,macOS 因此可以验证
你下载到的文件未被篡改。请只从
[Releases 页面](https://github.com/javaidea/mCalendar/releases)下载。

## 变更

本政策如有变更,会体现在这个文件里,并保留在仓库的提交历史中——你可以清楚看到
改了什么、什么时候改的。上一次变更是加入节假日功能——第一个用到网络的功能。

## 联系方式

有疑问请在 <https://github.com/javaidea/mCalendar/issues> 提 issue。
