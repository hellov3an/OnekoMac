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
        "update.downloading": [
            .english:  "Downloading…",
            .french:   "Téléchargement…",
            .japanese: "ダウンロード中…",
            .german:   "Wird geladen…",
            .spanish:  "Descargando…",
        ],
        "update.installing": [
            .english:  "Installing…",
            .french:   "Installation…",
            .japanese: "インストール中…",
            .german:   "Installiere…",
            .spanish:  "Instalando…",
        ],
        "update.install_btn": [
            .english:  "Install",
            .french:   "Installer",
            .japanese: "インストール",
            .german:   "Installieren",
            .spanish:  "Instalar",
        ],
        "update.error": [
            .english:  "Could not check for updates",
            .french:   "Impossible de vérifier les mises à jour",
            .japanese: "アップデートを確認できませんでした",
            .german:   "Konnte nicht auf Updates prüfen",
            .spanish:  "No se pudo verificar actualizaciones",
        ],

        // ── Wrapped ───────────────────────────────────────────────────────────
        "wrapped.btn": [
            .english:  "✦ Your Year in Numbers",
            .french:   "✦ Ton année en chiffres",
            .japanese: "✦ あなたの年間まとめ",
            .german:   "✦ Dein Jahr in Zahlen",
            .spanish:  "✦ Tu año en cifras",
        ],
        "wrapped.intro.eyebrow": [
            .english:  "YOUR YEAR IN NUMBERS",
            .french:   "TON ANNÉE EN CHIFFRES",
            .japanese: "今年を数字で振り返る",
            .german:   "DEIN JAHR IN ZAHLEN",
            .spanish:  "TU AÑO EN CIFRAS",
        ],
        "wrapped.intro.title": [
            .english:  "A year with",
            .french:   "Une année avec",
            .japanese: "と過ごした一年",
            .german:   "Ein Jahr mit",
            .spanish:  "Un año con",
        ],
        "wrapped.tap_hint": [
            .english:  "Tap anywhere to continue",
            .french:   "Touche n'importe où pour continuer",
            .japanese: "タップして続ける",
            .german:   "Tippe irgendwo um fortzufahren",
            .spanish:  "Toca en cualquier lugar para continuar",
        ],

        // Distance
        "wrapped.distance.label": [
            .english:  "YOU WALKED",
            .french:   "TU AS PARCOURU",
            .japanese: "一緒に歩いた距離",
            .german:   "IHR SEID GELAUFEN",
            .spanish:  "RECORRISTE",
        ],
        "wrapped.distance.phrase.0": [
            .english:  "Just a few pixels walked. Every journey starts somewhere!",
            .french:   "À peine quelques pixels parcourus. Tout commence quelque part !",
            .japanese: "ほんの数ピクセル。すべての旅はここから始まる！",
            .german:   "Nur ein paar Pixel gelaufen. Jede Reise beginnt irgendwo!",
            .spanish:  "Solo unos píxeles. ¡Todo viaje empieza en algún lugar!",
        ],
        "wrapped.distance.phrase.1": [
            .english:  "Look at you, actually walking this little cat!",
            .french:   "Dit donc, tu l'as fait marcher ce petit chat !",
            .japanese: "この小さな猫を歩かせたね！やるじゃないか！",
            .german:   "Schau an, du hast diese kleine Katze tatsächlich laufen lassen!",
            .spanish:  "¡Mira tú, haciendo caminar a este pequeño gato!",
        ],
        "wrapped.distance.phrase.2": [
            .english:  "Kilometers together. That's a real partnership.",
            .french:   "Des kilomètres ensemble. C'est une vraie équipe.",
            .japanese: "一緒にキロメートルを歩いた。本当のチームだ。",
            .german:   "Kilometer zusammen. Das ist echte Partnerschaft.",
            .spanish:  "Kilómetros juntos. Eso es una verdadera asociación.",
        ],
        "wrapped.distance.phrase.3": [
            .english:  "Honestly? Impressive. This cat has earned its stripes.",
            .french:   "Franchement ? C'est impressionnant. Ce chat a bien gagné ses galons.",
            .japanese: "正直なところ？すごい。この猫は本当に頑張った。",
            .german:   "Ehrlich gesagt? Beeindruckend. Diese Katze hat ihre Sporen verdient.",
            .spanish:  "¿Honestamente? Impresionante. Este gato se ha ganado sus galones.",
        ],
        "wrapped.distance.phrase.4": [
            .english:  "Legendary. Absolutely legendary. What else is there to say.",
            .french:   "Légendaire. Absolument légendaire. Que dire de plus.",
            .japanese: "伝説的。絶対に伝説的。もう何も言うことはない。",
            .german:   "Legendär. Absolut legendär. Was soll man da noch sagen.",
            .spanish:  "Legendario. Absolutamente legendario. Qué más se puede decir.",
        ],

        // Naps
        "wrapped.naps.label": [
            .english:  "NAPS TAKEN",
            .french:   "SIESTES EFFECTUÉES",
            .japanese: "昼寝の回数",
            .german:   "NICKERCHEN GEMACHT",
            .spanish:  "SIESTAS REALIZADAS",
        ],
        "wrapped.naps.phrase.0": [
            .english:  "Not even five naps. A truly dedicated cat.",
            .french:   "Même pas cinq siestes. Un chat de compétition.",
            .japanese: "5回も昼寝しなかった。本当に頑張り屋の猫だ。",
            .german:   "Nicht mal fünf Nickerchen. Eine wirklich engagierte Katze.",
            .spanish:  "Ni siquiera cinco siestas. Un gato verdaderamente dedicado.",
        ],
        "wrapped.naps.phrase.1": [
            .english:  "A well-rested cat is a happy cat.",
            .french:   "Un chat bien reposé est un chat heureux.",
            .japanese: "よく休んだ猫は幸せな猫。",
            .german:   "Eine gut ausgeruhte Katze ist eine glückliche Katze.",
            .spanish:  "Un gato bien descansado es un gato feliz.",
        ],
        "wrapped.naps.phrase.2": [
            .english:  "Certified expert in the noble art of napping.",
            .french:   "Expert certifié dans le noble art de la sieste.",
            .japanese: "昼寝という崇高な芸術の認定エキスパート。",
            .german:   "Zertifizierter Experte in der edlen Kunst des Nickerchens.",
            .spanish:  "Experto certificado en el noble arte de la siesta.",
        ],
        "wrapped.naps.phrase.3": [
            .english:  "This cat sleeps more than you do. And we respect it.",
            .french:   "Ce chat dort probablement plus que toi. Et on respecte ça.",
            .japanese: "この猫はあなたより多く寝ている。そして、それを尊重する。",
            .german:   "Diese Katze schläft mehr als du. Und das respektieren wir.",
            .spanish:  "Este gato duerme más que tú. Y lo respetamos.",
        ],

        // Scratches
        "wrapped.scratches.label": [
            .english:  "SCRATCHES",
            .french:   "GRIFFADES",
            .japanese: "引っかき回数",
            .german:   "KRATZER",
            .spanish:  "ARAÑAZOS",
        ],
        "wrapped.scratches.phrase.0": [
            .english:  "Your walls are immaculate. Well done.",
            .french:   "Tes murs sont impeccables. Bravo.",
            .japanese: "壁は完璧。よくやった。",
            .german:   "Deine Wände sind makellos. Gut gemacht.",
            .spanish:  "Tus paredes están impecables. Bien hecho.",
        ],
        "wrapped.scratches.phrase.1": [
            .english:  "A few scratches. Nothing a lick of paint won't fix.",
            .french:   "Quelques griffures. Rien que la peinture ne peut pas cacher.",
            .japanese: "少し引っかき傷が。ペンキ一塗りで直るよ。",
            .german:   "Einige Kratzer. Nichts, was Farbe nicht richten kann.",
            .spanish:  "Algunos arañazos. Nada que una capa de pintura no solucione.",
        ],
        "wrapped.scratches.phrase.2": [
            .english:  "This cat has left its mark — literally.",
            .french:   "Ce chat a laissé sa marque — au sens propre.",
            .japanese: "この猫は文字通り、その痕跡を残した。",
            .german:   "Diese Katze hat ihre Spuren hinterlassen — buchstäblich.",
            .spanish:  "Este gato ha dejado su marca — literalmente.",
        ],
        "wrapped.scratches.phrase.3": [
            .english:  "Your walls have a soul now. We'd call it art.",
            .french:   "Tes murs ont une âme maintenant. On appelle ça de l'art.",
            .japanese: "壁に魂が宿った。これはアートと呼ぼう。",
            .german:   "Deine Wände haben jetzt eine Seele. Wir nennen das Kunst.",
            .spanish:  "Tus paredes tienen alma ahora. Lo llamaríamos arte.",
        ],

        // Days
        "wrapped.days.label": [
            .english:  "DAYS TOGETHER",
            .french:   "JOURS ENSEMBLE",
            .japanese: "一緒に過ごした日数",
            .german:   "TAGE ZUSAMMEN",
            .spanish:  "DÍAS JUNTOS",
        ],
        "wrapped.days.phrase.0": [
            .english:  "A beautiful adventure just getting started.",
            .french:   "Une belle aventure qui commence tout juste.",
            .japanese: "始まったばかりの美しい冒険。",
            .german:   "Ein wunderschönes Abenteuer, das gerade erst beginnt.",
            .spanish:  "Una hermosa aventura que apenas comienza.",
        ],
        "wrapped.days.phrase.1": [
            .english:  "Already a week? This cat is part of the furniture now.",
            .french:   "Déjà une semaine ? Ce chat fait partie du décor maintenant.",
            .japanese: "もう一週間？この猫はもう家の一部だ。",
            .german:   "Schon eine Woche? Diese Katze gehört jetzt zum Inventar.",
            .spanish:  "¿Ya una semana? Este gato ya forma parte del mobiliario.",
        ],
        "wrapped.days.phrase.2": [
            .english:  "A month and more together. A real cohabitation.",
            .french:   "Un mois et plus ensemble. Une vraie colocation.",
            .japanese: "一ヶ月以上一緒に。本当の共同生活だ。",
            .german:   "Ein Monat und mehr zusammen. Eine echte Wohngemeinschaft.",
            .spanish:  "Un mes y más juntos. Una verdadera convivencia.",
        ],
        "wrapped.days.phrase.3": [
            .english:  "Almost a year. This cat knows you by heart.",
            .french:   "Presque un an. Ce chat te connaît par cœur.",
            .japanese: "もうすぐ一年。この猫はあなたのことを熟知している。",
            .german:   "Fast ein Jahr. Diese Katze kennt dich in- und auswendig.",
            .spanish:  "Casi un año. Este gato te conoce de memoria.",
        ],
        "wrapped.days.phrase.4": [
            .english:  "A year and more. Official: you two are inseparable.",
            .french:   "Un an et plus. Officiel : vous êtes inséparables.",
            .japanese: "一年以上。公式発表：あなたたちは切っても切れない仲だ。",
            .german:   "Ein Jahr und mehr. Offiziell: Ihr seid unzertrennlich.",
            .spanish:  "Un año y más. Oficial: son inseparables.",
        ],

        // Outro
        "wrapped.outro.title": [
            .english:  "See you tomorrow ✦",
            .french:   "À demain ✦",
            .japanese: "また明日 ✦",
            .german:   "Bis morgen ✦",
            .spanish:  "Hasta mañana ✦",
        ],
        "wrapped.outro.sub": [
            .english:  "Your little cat will be here.",
            .french:   "Ton petit chat sera là.",
            .japanese: "あなたの小さな猫がここにいるよ。",
            .german:   "Deine kleine Katze wird da sein.",
            .spanish:  "Tu pequeño gato estará aquí.",
        ],
        "wrapped.close": [
            .english:  "Close",
            .french:   "Fermer",
            .japanese: "閉じる",
            .german:   "Schließen",
            .spanish:  "Cerrar",
        ],
    ]
}
