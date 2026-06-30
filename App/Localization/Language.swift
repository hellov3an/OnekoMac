import Foundation

// MARK: – Language enum

enum Language: String, CaseIterable, Identifiable {
    case english  = "en"
    case french   = "fr"
    case japanese = "ja"
    case german   = "de"
    case spanish  = "es"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .english:  "🇬🇧"
        case .french:   "🇫🇷"
        case .japanese: "🇯🇵"
        case .german:   "🇩🇪"
        case .spanish:  "🇪🇸"
        }
    }

    var displayName: String {
        switch self {
        case .english:  "English"
        case .french:   "Français"
        case .japanese: "日本語"
        case .german:   "Deutsch"
        case .spanish:  "Español"
        }
    }
}

// MARK: – LanguageManager

import Combine

final class LanguageManager: ObservableObject {
    @Published private(set) var language: Language

    init() {
        if let stored = UserDefaults.standard.string(forKey: "app_language"),
           let lang = Language(rawValue: stored) {
            language = lang
        } else {
            // Auto-detect from system locale.
            let code = Locale.preferredLanguages.first ?? "en"
            if      code.hasPrefix("fr") { language = .french }
            else if code.hasPrefix("ja") { language = .japanese }
            else if code.hasPrefix("de") { language = .german }
            else if code.hasPrefix("es") { language = .spanish }
            else                         { language = .english }
        }
    }

    func set(_ lang: Language) {
        language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: "app_language")
    }

    subscript(_ key: String) -> String {
        Strings.table[key]?[language]
            ?? Strings.table[key]?[.english]
            ?? key
    }
}

// MARK: – Strings table

enum Strings {
    static let table: [String: [Language: String]] = [

        // ── Onboarding – Concept ──────────────────────────────────────────────
        "ob.concept.eyebrow": [
            .english:  "Inspired by the 1989 original",
            .french:   "Inspiré de l'original de 1989",
            .japanese: "1989年のオリジナルに着想",
            .german:   "Inspiriert vom Original von 1989",
            .spanish:  "Inspirado en el original de 1989",
        ],
        "ob.concept.title": [
            .english:  "A pixel cat\nfor your Mac",
            .french:   "Un chat pixel\npour ton Mac",
            .japanese: "Macのための\nピクセル猫",
            .german:   "Eine Pixelkatze\nfür deinen Mac",
            .spanish:  "Un gato pixel\npara tu Mac",
        ],
        "ob.concept.f1": [
            .english:  "Follows your cursor — everywhere",
            .french:   "Suit ton curseur — partout",
            .japanese: "カーソルをどこでも追いかける",
            .german:   "Folgt deinem Cursor — überall",
            .spanish:  "Sigue tu cursor — a todas partes",
        ],
        "ob.concept.f2": [
            .english:  "Idles, scratches walls, falls asleep",
            .french:   "Se repose, gratte les murs, s'endort",
            .japanese: "休んで、壁を引っかいて、眠る",
            .german:   "Ruht, kratzt Wände, schläft ein",
            .spanish:  "Descansa, araña paredes, se duerme",
        ],
        "ob.concept.f3": [
            .english:  "Crosses between all your screens",
            .french:   "Traverse tous tes écrans",
            .japanese: "すべての画面を行き来する",
            .german:   "Wechselt zwischen all deinen Bildschirmen",
            .spanish:  "Cruza entre todas tus pantallas",
        ],

        // ── Onboarding – Language ─────────────────────────────────────────────
        "ob.lang.title": [
            .english:  "Choose your language",
            .french:   "Choisissez votre langue",
            .japanese: "言語を選んでください",
            .german:   "Wähle deine Sprache",
            .spanish:  "Elige tu idioma",
        ],

        // ── Onboarding – Cat ──────────────────────────────────────────────────
        "ob.cat.title": [
            .english:  "Pick your companion",
            .french:   "Choisissez votre compagnon",
            .japanese: "相棒を選んでください",
            .german:   "Wähle deinen Begleiter",
            .spanish:  "Elige tu compañero",
        ],
        "ob.cat.subtitle": [
            .english:  "You can switch anytime in settings.",
            .french:   "Modifiable à tout moment dans les réglages.",
            .japanese: "設定でいつでも変更できます。",
            .german:   "In den Einstellungen jederzeit änderbar.",
            .spanish:  "Puedes cambiarlo en cualquier momento.",
        ],

        // ── Onboarding – Welcome ──────────────────────────────────────────────
        "ob.welcome.title": [
            .english:  "Welcome to OnekoMac",
            .french:   "Bienvenue sur OnekoMac",
            .japanese: "OnekoMacへようこそ",
            .german:   "Willkommen bei OnekoMac",
            .spanish:  "Bienvenido a OnekoMac",
        ],
        "ob.welcome.subtitle": [
            .english:  "Your cat is ready.",
            .french:   "Ton chat est prêt.",
            .japanese: "猫の準備ができました。",
            .german:   "Deine Katze ist bereit.",
            .spanish:  "Tu gato está listo.",
        ],

        // ── Navigation buttons ────────────────────────────────────────────────
        "btn.next": [
            .english:  "Next",
            .french:   "Suivant",
            .japanese: "次へ",
            .german:   "Weiter",
            .spanish:  "Siguiente",
        ],
        "btn.back": [
            .english:  "Back",
            .french:   "Retour",
            .japanese: "戻る",
            .german:   "Zurück",
            .spanish:  "Atrás",
        ],
        "btn.start": [
            .english:  "Let's go!",
            .french:   "C'est parti !",
            .japanese: "さあ、行こう！",
            .german:   "Los geht's!",
            .spanish:  "¡Vamos!",
        ],

        // ── Settings ──────────────────────────────────────────────────────────
        "settings.skin": [
            .english:  "Skin",
            .french:   "Skin",
            .japanese: "スキン",
            .german:   "Skin",
            .spanish:  "Skin",
        ],
        "settings.stats": [
            .english:  "Statistics",
            .french:   "Statistiques",
            .japanese: "統計",
            .german:   "Statistiken",
            .spanish:  "Estadísticas",
        ],
        "settings.updates": [
            .english:  "Updates",
            .french:   "Mises à jour",
            .japanese: "アップデート",
            .german:   "Updates",
            .spanish:  "Actualizaciones",
        ],
        "settings.debug": [
            .english:  "Debug",
            .french:   "Debug",
            .japanese: "デバッグ",
            .german:   "Debug",
            .spanish:  "Debug",
        ],
        "settings.reset": [
            .english:  "Reset",
            .french:   "Réinitialiser",
            .japanese: "リセット",
            .german:   "Zurücksetzen",
            .spanish:  "Restablecer",
        ],
        "settings.quit": [
            .english:  "Quit OnekoMac",
            .french:   "Quitter OnekoMac",
            .japanese: "OnekoMacを終了",
            .german:   "OnekoMac beenden",
            .spanish:  "Salir de OnekoMac",
        ],
        "settings.check_btn": [
            .english:  "Check",
            .french:   "Vérifier",
            .japanese: "確認",
            .german:   "Prüfen",
            .spanish:  "Verificar",
        ],
        "settings.download_btn": [
            .english:  "Download",
            .french:   "Télécharger",
            .japanese: "ダウンロード",
            .german:   "Herunterladen",
            .spanish:  "Descargar",
        ],

        // ── Stats labels ──────────────────────────────────────────────────────
        "stats.walked": [
            .english:  "walked",
            .french:   "parcourus",
            .japanese: "歩いた",
            .german:   "gelaufen",
            .spanish:  "recorridos",
        ],
        "stats.nap": [
            .english:  "nap",
            .french:   "sieste",
            .japanese: "昼寝",
            .german:   "Nickerchen",
            .spanish:  "siesta",
        ],
        "stats.naps": [
            .english:  "naps",
            .french:   "siestes",
            .japanese: "昼寝",
            .german:   "Nickerchen",
            .spanish:  "siestas",
        ],
        "stats.scratch": [
            .english:  "scratch",
            .french:   "grattage",
            .japanese: "引っかき",
            .german:   "Kratzen",
            .spanish:  "rasguño",
        ],
        "stats.scratches": [
            .english:  "scratches",
            .french:   "grattages",
            .japanese: "引っかき",
            .german:   "Kratzer",
            .spanish:  "rasguños",
        ],
        "stats.together": [
            .english:  "together",
            .french:   "ensemble",
            .japanese: "一緒に",
            .german:   "zusammen",
            .spanish:  "juntos",
        ],

        // ── Update status ─────────────────────────────────────────────────────
        "update.never": [
            .english:  "Never checked",
            .french:   "Jamais vérifié",
            .japanese: "未確認",
            .german:   "Nie geprüft",
            .spanish:  "Nunca verificado",
        ],
        "update.checking": [
            .english:  "Checking…",
            .french:   "Vérification…",
            .japanese: "確認中…",
            .german:   "Wird geprüft…",
            .spanish:  "Verificando…",
        ],
        "update.up_to_date": [
            .english:  "Up to date",
            .french:   "À jour",
            .japanese: "最新版",
            .german:   "Aktuell",
            .spanish:  "Al día",
        ],
        "update.available": [
            .english:  "available",
            .french:   "disponible",
            .japanese: "利用可能",
            .german:   "verfügbar",
            .spanish:  "disponible",
        ],
        "update.error": [
            .english:  "Could not check for updates",
            .french:   "Impossible de vérifier les mises à jour",
            .japanese: "アップデートを確認できませんでした",
            .german:   "Konnte nicht auf Updates prüfen",
            .spanish:  "No se pudo verificar actualizaciones",
        ],
    ]
}
