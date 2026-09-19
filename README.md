# Mini Calendar (mCalendar)

A minimal, keyboard-free macOS menu bar calendar. Click the date in your menu
bar to see one continuous grid spanning up to six months — nothing more,
nothing less.

<p align="center">
  <img src="docs/screenshot-light.png" width="360" alt="Mini Calendar showing September to November 2026 with lunar dates and holidays, in the light appearance and English, with the details of 1 October (National Day) open">
  &nbsp;&nbsp;
  <img src="docs/screenshot-dark.png" width="360" alt="Mini Calendar showing September to November 2026 with lunar dates and holidays, in the dark appearance and Chinese, with the details of 26 September (Mid-Autumn Festival) open">
</p>

<p align="center"><sub>Lunar dates and holidays switched on; click any day for its details.<br>
开启农历和节假日后的样子;点击任意一天可查看详情。</sub></p>

## Why

I built Mini Calendar for one small, recurring moment: when I'm planning
something and just need to *see* a calendar — what weekday a date falls on,
how the next few weeks line up. Opening the full Calendar app for that always
felt like too much.

So this app does exactly one thing: click the menu bar, and a calendar is in
front of you. No events, no reminders, no accounts — and there never will be.
This is intentional: I'm not going to keep integrating features. A calendar
you can glance at, instantly, that stays out of the way — that's the whole
product.

## 为什么做这个

做这个应用的初衷很简单:做计划的时候,我常常只是想**看一眼日历**——某天是星期几、
接下来几周怎么排。为了看个日期去打开完整的日历应用,总觉得太重了。

所以它只做一件事:点一下菜单栏,日历就在眼前。没有日程、没有提醒、不用登录
账号——将来也不会有。这是有意为之:我不打算继续往里集成功能。一个点开就能
看到日历、看完就退开的小工具,这就是它的全部。

## Features

- **Menu bar label** shows the current date and weekday (each can be toggled
  off; falls back to a calendar icon)
- **Continuous multi-month view**: 1–6 months in a single scrolling-free grid,
  the current month bright, following months dimmed
- **Drag the grip** under the grid to open or close months on the spot (or set
  the count in Settings)
- **Week numbers** in the left gutter, with the month abbreviation marking the
  week each month starts (column can be hidden)
- **Lunar dates** (农历) under each day, with the **24 solar terms** in blue on
  the days they fall. Optional, and computed on your Mac
- **Public holidays** as a coloured dot above the day, one colour per country:
  China, Finland, Estonia, the US and Kazakhstan. China's make-up workdays
  (调休上班) are marked "班". Optional and off by default; it is the only
  feature that uses the network (see [Privacy](#privacy))
- **Click any day** for its details: full date, lunar date, solar term, each
  country's holiday names, make-up workday and ISO week number
- Day cells only grow when lunar dates or holidays are on, so the plain grid
  stays as compact as before
- **Today** highlighted, `‹ ◯ ›` to page months / jump back to today
- **Monday-first** weeks, weekends dimmed
- **Light / dark / system** appearance
- **English / 中文** interface (or follow the system language)
- Right-click the menu bar icon for About / Quit
- Settings live in a standalone window (gear button in the popover)

## Download

Grab `mCalendar-x.y.zip` from the
[Releases page](https://github.com/mynaturefriends/mCalendar/releases), unzip,
and drag `mCalendar.app` into `/Applications`.

Builds from v1.0.1 on are signed with a Developer ID certificate and notarized
by Apple, so they open normally — no security warning, no right-click dance.
(中文:v1.0.1 起已通过 Apple 公证,下载后可直接打开。)

## Privacy

Mini Calendar collects nothing and sends nothing about you. The only network
access is downloading public holiday lists, and only after you turn holidays
on (they are off by default). Preferences are stored locally. See
[PRIVACY.md](PRIVACY.md) for exactly which hosts are contacted and how to
verify it yourself.

(中文:不收集任何信息;只有在你打开"显示节假日"后才会联网下载公开的节假日列表,
默认关闭。详见 [PRIVACY.md](PRIVACY.md)。)

## Requirements

- macOS 13+
- Xcode 15+ (Swift 5.9) to build

## Build & Run

Open `mCalendar.xcodeproj` in Xcode and hit **⌘R**.

Command line alternatives:

```sh
# Release app + distribution zip, output under build/
./scripts/release.sh

# Or via Xcode's build system directly
xcodebuild -project mCalendar.xcodeproj -scheme mCalendar -configuration Release build

# Or run the bare executable via SwiftPM (no app bundle)
swift run
```

The app is a menu-bar-only agent (`LSUIElement`): it shows no Dock icon and no
main window. To launch it at login, add the built app to
**System Settings → General → Login Items**.

## 简介

一个极简的 macOS 菜单栏日历:点击菜单栏上的日期,弹出一张连续显示 1–6 个月的
日历,拖动日历下方的小横条即可随手增减月份。支持周数列、今天高亮、浅色/深色外观、
中英文界面。可选显示农历和二十四节气(本机计算),以及中国、芬兰、爱沙尼亚、美国、
哈萨克斯坦的节假日(彩色圆点标注,中国调休上班日标"班";默认关闭,是唯一联网的功能)。
点击任意一天可查看详情。设置在独立窗口中,菜单栏图标右键可退出。

## License

[MIT](LICENSE) © 2026 Zhou Yang
