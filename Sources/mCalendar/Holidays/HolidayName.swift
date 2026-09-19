/// One holiday's name, as the country itself writes it plus its English name.
///
/// The details popover shows `local` with a translation underneath: the
/// English name in the English interface, a Chinese one in the Chinese
/// interface.
struct HolidayName: Hashable {
    let local: String
    let english: String

    /// The name to show under `local` in the given interface language, or nil
    /// when it would only repeat it (US holidays in English, Chinese in Chinese).
    /// A holiday missing from the Chinese table falls back to English.
    func translation(chinese: Bool) -> String? {
        let t = chinese ? HolidayName.chinese[english] ?? english : english
        return t == local ? nil : t
    }

    /// A name from China's schedule, which arrives in Chinese only.
    static func china(_ name: String) -> HolidayName {
        HolidayName(local: name, english: chinaInEnglish[name] ?? name)
    }

    // MARK: - Translation tables

    /// Chinese names for every national holiday of the supported countries,
    /// keyed by the English name date.nager.at uses.
    private static let chinese: [String: String] = [
        // Shared by several countries
        "New Year's Day": "元旦", "Epiphany": "主显节", "Good Friday": "耶稣受难日",
        "Easter Sunday": "复活节", "Easter Monday": "复活节星期一", "Ascension Day": "耶稣升天节",
        "Pentecost": "圣灵降临节", "All Saints' Day": "诸圣节", "Christmas Eve": "平安夜",
        "Christmas Day": "圣诞节", "St. Stephen's Day": "圣诞节次日", "May Day": "五一节",
        "Labour Day": "劳动节", "Midsummer Eve": "仲夏夜", "Midsummer Day": "仲夏节",
        "Independence Day": "独立日",
        // Estonia
        "Spring Day": "春日节", "Victory Day": "胜利日",
        "Day of Restoration of Independence": "恢复独立日",
        // United States
        "Martin Luther King, Jr. Day": "马丁·路德·金纪念日", "Presidents Day": "总统日",
        "Memorial Day": "阵亡将士纪念日", "Juneteenth National Independence Day": "六月节",
        "Columbus Day": "哥伦布日", "Indigenous Peoples' Day": "原住民日",
        "Veterans Day": "退伍军人节", "Thanksgiving Day": "感恩节",
        // Kazakhstan
        "International Women's Day": "国际妇女节", "Nauryz Meyramy": "纳吾肉孜节",
        "Kazakhstan People's Unity Day": "哈萨克斯坦人民团结日",
        "Defender of the Fatherland Day": "祖国保卫者日",
        "Great Patriotic War Against Fascism Victory Day": "卫国战争胜利日",
        "Orthodox Christmas": "东正教圣诞节", "Kurban Ait": "古尔邦节", "Capital City Day": "首都日",
        "Constitution Day": "宪法日", "Republic Day": "共和国日"
    ]

    /// English names for the holidays in China's schedule.
    private static let chinaInEnglish: [String: String] = [
        "元旦": "New Year's Day", "春节": "Spring Festival", "清明节": "Qingming Festival",
        "劳动节": "Labour Day", "端午节": "Dragon Boat Festival", "中秋节": "Mid-Autumn Festival",
        "国庆节": "National Day"
    ]
}
