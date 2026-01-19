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
}
