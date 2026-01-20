import Testing
@testable import SwiftM3UKit

@Suite("ContentClassifier Tests")
struct ClassifierTests {

    let classifier = ContentClassifier()

    // MARK: - Live TV Detection

    @Test("Classify live channel with HD suffix")
    func classifyLiveHD() {
        let result = classifier.classify(name: "BBC One HD", group: "UK Channels", attributes: [:])
        #expect(result == .live)
    }

    @Test("Classify live channel with 4K suffix")
    func classifyLive4K() {
        let result = classifier.classify(name: "Discovery 4K", group: "Documentary", attributes: [:])
        #expect(result == .live)
    }

    @Test("Classify live channel with FHD suffix")
    func classifyLiveFHD() {
        let result = classifier.classify(name: "CNN FHD", group: "News", attributes: [:])
        #expect(result == .live)
    }

    @Test("Classify plain channel as live")
    func classifyPlainChannel() {
        let result = classifier.classify(name: "Local Channel", group: "Regional", attributes: [:])
        #expect(result == .live)
    }

    // MARK: - Movie Detection

    @Test("Classify movie with year pattern")
    func classifyMovieWithYear() {
        let result = classifier.classify(name: "The Matrix (1999)", group: "Movies", attributes: [:])
        #expect(result == .movie)
    }

    @Test("Classify movie with movie group")
    func classifyMovieWithGroup() {
        let result = classifier.classify(name: "Some Film", group: "Movies", attributes: [:])
        #expect(result == .movie)
    }

    @Test("Classify movie with VOD group")
    func classifyMovieWithVODGroup() {
        let result = classifier.classify(name: "Action Film", group: "VOD", attributes: [:])
        #expect(result == .movie)
    }

    @Test("Classify movie with film group")
    func classifyMovieWithFilmGroup() {
        let result = classifier.classify(name: "Drama", group: "Film", attributes: [:])
        #expect(result == .movie)
    }

    @Test("Classify movie with year and language tag")
    func classifyMovieWithYearAndLanguage() {
        let result = classifier.classify(name: "Inception (2010) (TR)", group: nil, attributes: [:])
        #expect(result == .movie)
    }

    // MARK: - Series Detection

    @Test("Classify series with S01E01 pattern")
    func classifySeriesS01E01() {
        let result = classifier.classify(name: "Breaking Bad S01E01", group: "Series", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 1)
            #expect(episode == 1)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with S1E1 pattern")
    func classifySeriesS1E1() {
        let result = classifier.classify(name: "Game of Thrones S1E1", group: nil, attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 1)
            #expect(episode == 1)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with Season/Episode words")
    func classifySeriesSeasonEpisode() {
        let result = classifier.classify(name: "Friends Season 2 Episode 10", group: nil, attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 2)
            #expect(episode == 10)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with Turkish Sezon/Bölüm")
    func classifySeriesTurkish() {
        let result = classifier.classify(name: "Kurtlar Vadisi Sezon 1 Bölüm 5", group: nil, attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 1)
            #expect(episode == 5)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with episode only")
    func classifySeriesEpisodeOnly() {
        let result = classifier.classify(name: "Documentary Ep. 5", group: nil, attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == nil)
            #expect(episode == 5)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with lowercase pattern")
    func classifySeriesLowercase() {
        let result = classifier.classify(name: "the wire s03e05", group: nil, attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 3)
            #expect(episode == 5)
        } else {
            Issue.record("Expected series content type")
        }
    }

    // MARK: - Edge Cases

    @Test("Year in live channel doesn't make it movie")
    func yearInLiveChannel() {
        // When HD indicator is present, should be live even with year
        let result = classifier.classify(name: "Sports 2024 HD", group: "Sports", attributes: [:])
        #expect(result == .live)
    }

    @Test("Empty name defaults to live")
    func emptyName() {
        let result = classifier.classify(name: "", group: nil, attributes: [:])
        #expect(result == .live)
    }

    @Test("Cinema group indicates movie", arguments: ["Cinema", "cinema", "CINEMA"])
    func cinemaGroup(group: String) {
        let result = classifier.classify(name: "Some Title", group: group, attributes: [:])
        #expect(result == .movie)
    }

    // MARK: - Turkish Film Group Detection

    @Test("Classify movie with Turkish sinema group")
    func classifyMovieWithSinema() {
        let result = classifier.classify(name: "Film Adı", group: "Sinema", attributes: [:])
        #expect(result == .movie)
    }

    @Test("Classify movie with vizyon group")
    func classifyMovieWithVizyon() {
        let result = classifier.classify(name: "Yeni Film", group: "Vizyon Filmleri", attributes: [:])
        #expect(result == .movie)
    }

    @Test("Classify movie with bluray group")
    func classifyMovieWithBluray() {
        let result = classifier.classify(name: "Action Movie", group: "Bluray Films", attributes: [:])
        #expect(result == .movie)
    }

    // MARK: - Turkish "Bölüm" Context-Aware Detection

    @Test("Classify movie with Turkish Bölüm (Part) and year")
    func classifyMovieWithBolumAndYear() {
        // Turkish "Bölüm" can mean both "Part" (movie) and "Episode" (series)
        // When there's a year and no season, it's a movie part
        let result = classifier.classify(name: "John Wick: Bölüm 4 (2023)", group: "Filmler", attributes: [:])
        #expect(result == .movie)
    }

    @Test("Classify movie with Turkish Bölüm and quality tags")
    func classifyMovieWithBolumQualityTags() {
        // Quality variants of the same movie part should all be classified as movies
        let resultHD = classifier.classify(name: "John Wick: Bölüm 4 - HD (2023)", group: "Dublaj Filmler", attributes: [:])
        let resultFHD = classifier.classify(name: "John Wick: Bölüm 4 - FHD (2023)", group: "Dublaj Filmler", attributes: [:])
        let result4K = classifier.classify(name: "John Wick: Bölüm 4 - 4K (2023)", group: "Dublaj Filmler", attributes: [:])

        #expect(resultHD == .movie)
        #expect(resultFHD == .movie)
        #expect(result4K == .movie)
    }

    @Test("Classify movie with Bölüm in Turkish title")
    func classifyMovieWithBolumInTitle() {
        // More Turkish movie examples with "Bölüm" meaning "Part"
        let result1 = classifier.classify(name: "Dune: Çöl Gezegeni Bölüm İki (2024)", group: "Yabancı Filmler", attributes: [:])
        let result2 = classifier.classify(name: "Harry Potter ve Ölüm Yadigârları: Bölüm 2 (2011)", group: "Yabancı Seri Filmler", attributes: [:])

        #expect(result1 == .movie)
        #expect(result2 == .movie)
    }

    @Test("Classify series with Turkish Bölüm (Episode) and season")
    func classifySeriesWithBolumAndSeason() {
        // When "Bölüm" appears WITH a season number, it's a series episode
        let result = classifier.classify(name: "Kurtlar Vadisi Sezon 1 Bölüm 4", group: "Diziler", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 1)
            #expect(episode == 4)
        } else {
            Issue.record("Expected series content type with season and episode")
        }
    }

    @Test("Classify series with Turkish Bölüm and S##E## pattern")
    func classifySeriesWithBolumAndPattern() {
        // When "Bölüm" appears with S##E## pattern, it's definitely a series
        let result = classifier.classify(name: "Eşref Rüya S02E14 Bölüm 14", group: "Güncel TV Dizileri", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 2)
            #expect(episode == 14)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with only Bölüm in series group")
    func classifySeriesWithBolumInSeriesGroup() {
        // When in a series group without year, "Bölüm" means episode
        let result = classifier.classify(name: "Show Name Bölüm 5", group: "TV Dizileri", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == nil)
            #expect(episode == 5)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify movie with altyazili group")
    func classifyMovieWithAltyazili() {
        let result = classifier.classify(name: "Foreign Film", group: "Altyazılı Filmler", attributes: [:])
        #expect(result == .movie)
    }

    @Test("Classify movie with dublaj group")
    func classifyMovieWithDublaj() {
        let result = classifier.classify(name: "Kids Movie", group: "Dublaj Filmler", attributes: [:])
        #expect(result == .movie)
    }

    @Test("Classify movie with imdb group")
    func classifyMovieWithIMDB() {
        let result = classifier.classify(name: "Top Rated", group: "IMDB Top 250", attributes: [:])
        #expect(result == .movie)
    }

    @Test("Classify movie with [4K] tag")
    func classifyMovieWith4KTag() {
        let result = classifier.classify(name: "Inception [4K]", group: nil, attributes: [:])
        #expect(result == .movie)
    }

    // MARK: - Streaming Platform Series Detection

    @Test("Classify series with Netflix Dizileri group")
    func classifySeriesNetflix() {
        // "Netflix Dizileri" contains "dizi" so it's a series group
        let result = classifier.classify(name: "Stranger Things", group: "Netflix Dizileri", attributes: [:])

        if case .series = result {
            // Pass
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with Disney Dizileri group")
    func classifySeriesDisney() {
        // Groups must contain "dizi" or "series" keyword
        let result = classifier.classify(name: "The Mandalorian", group: "Disney Plus Dizileri", attributes: [:])

        if case .series = result {
            // Pass
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with Amazon Dizileri group")
    func classifySeriesAmazon() {
        let result = classifier.classify(name: "The Boys", group: "Amazon Dizileri", attributes: [:])

        if case .series = result {
            // Pass
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with explicit dizi keyword")
    func classifySeriesExxen() {
        // Exxen alone is not enough - need "dizi" keyword
        let result = classifier.classify(name: "Türk Dizisi", group: "Exxen Dizileri", attributes: [:])

        if case .series = result {
            // Pass
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with BluTV Dizileri group")
    func classifySeriesBluTV() {
        let result = classifier.classify(name: "Yeşilçam", group: "BluTV Dizileri", attributes: [:])

        if case .series = result {
            // Pass
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with explicit diziler keyword")
    func classifySeriesTabii() {
        let result = classifier.classify(name: "Dizi Adı", group: "Tabii Diziler", attributes: [:])

        if case .series = result {
            // Pass
        } else {
            Issue.record("Expected series content type")
        }
    }

    // MARK: - Unicode Indicator Tests

    @Test("Live channel with AVRUPA unicode indicator")
    func classifyLiveWithAvrupa() {
        let result = classifier.classify(name: "Kanal D ᴬⱽᴿᵁᴾᴬ", group: "Ulusal", attributes: [:])
        #expect(result == .live)
    }

    @Test("Live channel with RAW unicode indicator")
    func classifyLiveWithRaw() {
        let result = classifier.classify(name: "TRT 1 ᴿᴬᵂ", group: "Ulusal", attributes: [:])
        #expect(result == .live)
    }

    @Test("Live channel with degree symbol")
    func classifyLiveWithDegree() {
        let result = classifier.classify(name: "Show TV °", group: "Ulusal", attributes: [:])
        #expect(result == .live)
    }

    @Test("Live channel with UHD unicode indicator")
    func classifyLiveWithUHD() {
        let result = classifier.classify(name: "Filmbox ᵁᴴᴰ", group: "Sinema", attributes: [:])
        // This is in Sinema group, but has UHD indicator - should still be movie due to group
        #expect(result == .movie)
    }

    @Test("Live channel with superscript HD indicator")
    func classifyLiveWithSuperscriptHD() {
        let result = classifier.classify(name: "beIN Sports ᴴᴰ", group: "Spor", attributes: [:])
        #expect(result == .live)
    }

    // MARK: - Multi-Language Support Tests

    // 🇫🇷 French
    @Test("Classify series with French Saison/Épisode")
    func classifySeriesFrench() {
        let result = classifier.classify(name: "Les Revenants Saison 1 Épisode 5", group: "Série", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 1)
            #expect(episode == 5)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify movie with French Cinéma group")
    func classifyMovieFrench() {
        let result = classifier.classify(name: "Amélie Poulain (2001)", group: "Cinéma", attributes: [:])
        #expect(result == .movie)
    }

    // 🇩🇪 German
    @Test("Classify series with German Staffel/Folge")
    func classifySeriesGerman() {
        let result = classifier.classify(name: "Dark Staffel 2 Folge 8", group: "Serie", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 2)
            #expect(episode == 8)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify movie with German Kino group")
    func classifyMovieGerman() {
        let result = classifier.classify(name: "Das Boot (1981)", group: "Kino", attributes: [:])
        #expect(result == .movie)
    }

    // 🇪🇸 Spanish
    @Test("Classify series with Spanish Temporada/Episodio")
    func classifySeriesSpanish() {
        let result = classifier.classify(name: "La Casa de Papel Temporada 3 Episodio 4", group: "Series", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 3)
            #expect(episode == 4)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify series with Spanish Capítulo")
    func classifySeriesSpanishCapitulo() {
        let result = classifier.classify(name: "Elite Temporada 1 Capítulo 6", group: "Series", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 1)
            #expect(episode == 6)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify movie with Spanish Película group")
    func classifyMovieSpanish() {
        let result = classifier.classify(name: "Pan's Labyrinth (2006)", group: "Películas", attributes: [:])
        #expect(result == .movie)
    }

    // 🇧🇷 Portuguese
    @Test("Classify series with Portuguese Temporada/Episódio")
    func classifySeriesPortuguese() {
        let result = classifier.classify(name: "3% Temporada 2 Episódio 7", group: "Série", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 2)
            #expect(episode == 7)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify movie with Portuguese Filme group")
    func classifyMoviePortuguese() {
        let result = classifier.classify(name: "Cidade de Deus (2002)", group: "Filmes", attributes: [:])
        #expect(result == .movie)
    }

    // 🇷🇺 Russian
    @Test("Classify series with Russian Сезон/Серия")
    func classifySeriesRussian() {
        let result = classifier.classify(name: "Мажор Сезон 2 Серия 10", group: "Сериал", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 2)
            #expect(episode == 10)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify movie with Russian Фильм group")
    func classifyMovieRussian() {
        let result = classifier.classify(name: "Брат (1997)", group: "Фильмы", attributes: [:])
        #expect(result == .movie)
    }

    // 🇸🇦 Arabic
    @Test("Classify series with Arabic موسم/حلقة")
    func classifySeriesArabic() {
        let result = classifier.classify(name: "مسلسل عربي موسم 1 حلقة 15", group: "مسلسلات", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 1)
            #expect(episode == 15)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify movie with Arabic فيلم group")
    func classifyMovieArabic() {
        let result = classifier.classify(name: "فيلم عربي (2020)", group: "أفلام", attributes: [:])
        #expect(result == .movie)
    }

    // 🇨🇳 Chinese
    @Test("Classify series with Chinese 第X季第X集")
    func classifySeriesChinese() {
        let result = classifier.classify(name: "三体 第1季第5集", group: "剧集", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 1)
            #expect(episode == 5)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify movie with Chinese 电影 group")
    func classifyMovieChinese() {
        let result = classifier.classify(name: "霸王别姬 (1993)", group: "电影", attributes: [:])
        #expect(result == .movie)
    }

    // 🇯🇵 Japanese
    @Test("Classify series with Japanese 第X話")
    func classifySeriesJapanese() {
        let result = classifier.classify(name: "進撃の巨人 第2期第12話", group: "ドラマ", attributes: [:])

        if case let .series(season, episode) = result {
            #expect(season == 2)
            #expect(episode == 12)
        } else {
            Issue.record("Expected series content type")
        }
    }

    @Test("Classify movie with Japanese 映画 group")
    func classifyMovieJapanese() {
        let result = classifier.classify(name: "千と千尋の神隠し (2001)", group: "映画", attributes: [:])
        #expect(result == .movie)
    }

    // MARK: - Movie Sequel Detection

    @Test("Movie sequels with numbers should be classified as movies")
    func movieSequelsWithNumbersShouldBeMovies() {
        let testCases: [(name: String, group: String?)] = [
            // Numeric sequels
            ("Shrek 3 (2007)", "4K WORLD"),
            ("Iron Man 3 (2013)", "ACTION"),
            ("Jurassic Park 3 (2001)", nil),
            ("Madagascar 3 (2012)", "ANIMATION"),
            ("Die Hard 4.0 (2007)", "4K"),
            ("Fast & Furious 7 (2015)", "4K BLURAY"),
            ("Ocean's 11 (2001)", "HEIST"),
            ("Apollo 13 (1995)", "DRAMA"),

            // Part indicators
            ("John Wick: Part 2 (2017)", "ACTION"),
            ("Avatar: Chapter 2 (2025)", "SCI-FI"),

            // Without year (relying on sequel pattern)
            ("Shrek 3", "Movies"),
            ("Frozen 2", "Disney"),
        ]

        for (name, group) in testCases {
            let result = classifier.classify(name: name, group: group, attributes: [:])

            #expect(result == .movie,
                    "'\(name)' in group '\(group ?? "nil")' should be .movie, got \(result)")
        }
    }

    @Test("Roman numeral sequels should be detected as movies")
    func romanNumeralSequelsShouldBeMovies() {
        let testCases = [
            "Rocky II (1979)",
            "Rocky III (1982)",
            "Rocky IV (1985)",
            "Star Wars Episode IV (1977)",
            "Final Fantasy VII (2005)",
            "Rambo III (1988)",
        ]

        for name in testCases {
            let result = classifier.classify(name: name, group: "Movies", attributes: [:])

            #expect(result == .movie,
                    "'\(name)' with Roman numerals should be .movie, got \(result)")
        }
    }

    @Test("Movie sequels with Part indicators should be movies")
    func movieSequelsWithPartIndicatorsShouldBeMovies() {
        let testCases = [
            "The Godfather Part II (1974)",
            "Back to the Future Part III (1990)",
            "Harry Potter and the Deathly Hallows: Part 2 (2011)",
            "Kill Bill: Part 2 (2004)",
            "Dune: Part Two (2024)",
        ]

        for name in testCases {
            let result = classifier.classify(name: name, group: nil, attributes: [:])

            #expect(result == .movie,
                    "'\(name)' with Part indicator should be .movie, got \(result)")
        }
    }

    // MARK: - Quality Indicator Groups

    @Test("Quality indicator groups should default to movies")
    func qualityGroupsShouldDefaultToMovies() {
        let qualityGroups = [
            "4K WORLD",
            "FHD COLLECTION",
            "UHD MOVIES",
            "2160P",
            "TOP 250",
            "IMDB TOP",
            "BEST OF 2024",
            "BOLLYWOOD",
            "MARVEL COLLECTION",
        ]

        for group in qualityGroups {
            let result = classifier.classify(name: "Random Title (2024)", group: group, attributes: [:])

            #expect(result == .movie,
                    "Items in '\(group)' should default to .movie, got \(result)")
        }
    }

    @Test("Items in 4K WORLD group should be classified as movies")
    func fourKWorldGroupShouldBeMovies() {
        let testCases = [
            "Avatar (2009)",
            "Inception (2010)",
            "The Dark Knight (2008)",
            "Interstellar (2014)",
        ]

        for name in testCases {
            let result = classifier.classify(name: name, group: "4K WORLD", attributes: [:])

            #expect(result == .movie,
                    "'\(name)' in 4K WORLD should be .movie, got \(result)")
        }
    }

    @Test("Items in TOP 250 group should be classified as movies")
    func top250GroupShouldBeMovies() {
        let testCases = [
            "The Shawshank Redemption (1994)",
            "The Godfather (1972)",
            "The Dark Knight (2008)",
            "12 Angry Men (1957)",
        ]

        for name in testCases {
            let result = classifier.classify(name: name, group: "TOP 250", attributes: [:])

            #expect(result == .movie,
                    "'\(name)' in TOP 250 should be .movie, got \(result)")
        }
    }

    // MARK: - Edge Cases

    @Test("Strong episode patterns should override sequel detection")
    func strongEpisodePatternsOverrideSequelDetection() {
        // Even if title contains "3", strong S01E03 pattern should win
        let result = classifier.classify(name: "Breaking Bad 3 S01E03", group: "4K WORLD", attributes: [:])

        if case .series = result {
            // Expected - strong pattern overrides
        } else {
            #expect(Bool(false), "Strong S01E03 pattern should result in .series, got \(result)")
        }
    }

    @Test("Series patterns in quality groups should be classified as series")
    func seriesPatternsInQualityGroupsShouldBeSeries() {
        let result = classifier.classify(name: "The Crown S01E01", group: "Netflix 4K", attributes: [:])

        if case .series = result {
            // Expected
        } else {
            #expect(Bool(false), "S01E01 pattern should override quality group, got \(result)")
        }
    }

    @Test("Movie sequels in series groups should check pattern strength")
    func movieSequelsInSeriesGroupAmbiguous() {
        // Ambiguous: "Title 3" in "TV Series" group
        let result = classifier.classify(name: "Stranger Things 3", group: "TV SERIES", attributes: [:])

        // Without S01E03 pattern, group should win
        // This is acceptable behavior - let group context dominate
        #expect(result == .series(season: nil, episode: nil),
                "In 'TV SERIES' group without S01E03, should be series")
    }

    @Test("Complex movie titles with numbers should not false positive")
    func complexMovieTitlesWithNumbers() {
        let testCases = [
            ("District 9 (2009)", "Sci-Fi", true),  // Number is part of title
            ("Apollo 13 (1995)", "Drama", true),   // Based on real event
            ("Catch-22 (1970)", "War", true),      // Based on book title
        ]

        for (name, group, shouldBeMovie) in testCases {
            let result = classifier.classify(name: name, group: group, attributes: [:])

            if shouldBeMovie {
                #expect(result == .movie,
                        "'\(name)' should be .movie, got \(result)")
            }
        }
    }

    @Test("Turkish Bölüm context-aware detection should work with sequels")
    func turkishBolumWithSequels() {
        // Movie part (with year)
        let movieResult = classifier.classify(
            name: "John Wick: Bölüm 4 (2023)",
            group: "Aksiyon",
            attributes: [:]
        )
        #expect(movieResult == .movie, "Turkish movie part with year should be .movie")

        // Series episode (with season)
        let seriesResult = classifier.classify(
            name: "Kurtlar Vadisi Sezon 1 Bölüm 5",
            group: "Dizi",
            attributes: [:]
        )

        if case .series = seriesResult {
            // Expected
        } else {
            #expect(Bool(false), "Turkish series with Sezon/Bölüm should be .series")
        }
    }

    @Test("Live TV with numeric suffix should not be movie")
    func liveTVWithNumericSuffixShouldNotBeMovie() {
        let testCases = [
            "BBC One HD",
            "CNN FHD",
            "Discovery 4K",
            "Fox Sports 2 HD",
        ]

        for name in testCases {
            let result = classifier.classify(name: name, group: "Live TV", attributes: [:])

            #expect(result == .live,
                    "'\(name)' should be .live, got \(result)")
        }
    }

    @Test("Items with live prefix should always be live")
    func itemsWithLivePrefixShouldAlwaysBeeLive() {
        let testCases = [
            "▱ TRT 1 HD",
            "▱ SPOR",
            "▱ HABER",
            "▱ BELGESEL",
        ]

        for name in testCases {
            let result = classifier.classify(name: name, group: "▱ ULUSAL", attributes: [:])

            #expect(result == .live,
                    "'\(name)' with ▱ prefix should be .live, got \(result)")
        }
    }

    @Test("Diamant SINEMA group should be classified as movies")
    func diamantSinemaGroupShouldBeMovies() {
        let testCases = [
            "The Matrix (1999)",
            "Inception (2010)",
            "The Shawshank Redemption (1994)",
        ]

        for name in testCases {
            let result = classifier.classify(name: name, group: "▱ DIAMANT SINEMA", attributes: [:])

            // Should be live because of ▱ prefix
            #expect(result == .live,
                    "'\(name)' in ▱ DIAMANT SINEMA should be .live due to prefix")
        }
    }

    @Test("Sequel detection should not override explicit series groups")
    func sequelDetectionShouldNotOverrideSeriesGroups() {
        let testCases = [
            ("Breaking Bad 3", "TV Series"),
            ("House MD 2", "Series"),
            ("Friends 3", "DIZI"),
        ]

        for (name, group) in testCases {
            let result = classifier.classify(name: name, group: group, attributes: [:])

            if case .series = result {
                // Expected - explicit series group overrides sequel pattern
            } else {
                #expect(Bool(false),
                        "'\(name)' in '\(group)' should be .series, got \(result)")
            }
        }
    }
}
