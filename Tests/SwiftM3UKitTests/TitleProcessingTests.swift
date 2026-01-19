import Testing
import Foundation
@testable import SwiftM3UKit

@Suite("Title Processing Tests")
struct TitleProcessingTests {

    // MARK: - Turkish Character Normalization

    @Test("Normalize Turkish characters")
    func normalizeTurkishCharacters() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.normalizeTurkish("ç") == "c")
        #expect(normalizer.normalizeTurkish("Ç") == "C")
        #expect(normalizer.normalizeTurkish("ğ") == "g")
        #expect(normalizer.normalizeTurkish("Ğ") == "G")
        #expect(normalizer.normalizeTurkish("ı") == "i")
        #expect(normalizer.normalizeTurkish("İ") == "I")
        #expect(normalizer.normalizeTurkish("ö") == "o")
        #expect(normalizer.normalizeTurkish("Ö") == "O")
        #expect(normalizer.normalizeTurkish("ş") == "s")
        #expect(normalizer.normalizeTurkish("Ş") == "S")
        #expect(normalizer.normalizeTurkish("ü") == "u")
        #expect(normalizer.normalizeTurkish("Ü") == "U")
    }

    @Test("Normalize full Turkish text")
    func normalizeFullTurkishText() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.normalizeTurkish("Türkçe Şarkılar") == "Turkce Sarkilar")
        #expect(normalizer.normalizeTurkish("İstanbul Güneşi") == "Istanbul Gunesi")
        #expect(normalizer.normalizeTurkish("Çocuk Programları") == "Cocuk Programlari")
    }

    // MARK: - Title Normalization

    @Test("Normalize title with lowercase and trim")
    func normalizeTitleBasic() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.normalize("  BBC One HD  ") == "bbc one hd")
        #expect(normalizer.normalize("CNN INTERNATIONAL") == "cnn international")
    }

    @Test("Normalize title collapses whitespace")
    func normalizeTitleCollapsesWhitespace() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.normalize("BBC   One   HD") == "bbc one hd")
        #expect(normalizer.normalize("  Multiple   Spaces  ") == "multiple spaces")
    }

    @Test("Normalize title with Turkish characters")
    func normalizeTitleWithTurkish() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.normalize("Türkiye Kanalı") == "turkiye kanali")
        #expect(normalizer.normalize("SHOW TV İZLE") == "show tv izle")
    }

    // MARK: - Title Sanitization

    @Test("Sanitize removes country prefixes")
    func sanitizeRemovesCountryPrefixes() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.sanitize("TR: BBC One") == "BBC One")
        #expect(normalizer.sanitize("UK: Sky Sports") == "Sky Sports")
        #expect(normalizer.sanitize("US: ESPN") == "ESPN")
        #expect(normalizer.sanitize("DE: ARD") == "ARD")
        #expect(normalizer.sanitize("FR: TF1") == "TF1")
    }

    @Test("Sanitize removes quality prefixes")
    func sanitizeRemovesQualityPrefixes() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.sanitize("HD: BBC One") == "BBC One")
        #expect(normalizer.sanitize("FHD: Sky Sports") == "Sky Sports")
        #expect(normalizer.sanitize("4K: Netflix") == "Netflix")
        #expect(normalizer.sanitize("UHD: Disney+") == "Disney+")
    }

    @Test("Sanitize removes bracketed content")
    func sanitizeRemovesBracketedContent() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.sanitize("BBC One [HD]") == "BBC One")
        #expect(normalizer.sanitize("Sky Sports (UK)") == "Sky Sports")
        #expect(normalizer.sanitize("ESPN [1080p] (Sports)") == "ESPN")
    }

    @Test("Sanitize removes quality tags from end")
    func sanitizeRemovesQualityTags() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.sanitize("BBC One HD") == "BBC One")
        #expect(normalizer.sanitize("Sky Sports FHD") == "Sky Sports")
        #expect(normalizer.sanitize("ESPN 4K") == "ESPN")
        #expect(normalizer.sanitize("Fox Sports 1080p") == "Fox Sports")
        #expect(normalizer.sanitize("CNN HEVC") == "CNN")
    }

    @Test("Sanitize removes pipe-separated content")
    func sanitizeRemovesPipeSeparated() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.sanitize("BBC One | HD | UK") == "BBC One")
        #expect(normalizer.sanitize("ESPN|Sports") == "ESPN")
    }

    @Test("Sanitize complex title")
    func sanitizeComplexTitle() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.sanitize("TR: BBC One HD [1080p]") == "BBC One")
        #expect(normalizer.sanitize("UK: Sky Sports FHD (HD)") == "Sky Sports")
        #expect(normalizer.sanitize("VIP: ESPN 4K HEVC") == "ESPN")
    }

    // MARK: - M3UItem Extension Tests

    @Test("M3UItem cleanTitle property")
    func itemCleanTitleProperty() {
        let item = M3UItem(
            name: "TR: BBC One HD [1080p]",
            url: URL(string: "http://example.com")!
        )

        #expect(item.cleanTitle == "BBC One")
    }

    @Test("M3UItem normalizedTitle property")
    func itemNormalizedTitleProperty() {
        let item = M3UItem(
            name: "Türkiye Kanalı",
            url: URL(string: "http://example.com")!
        )

        #expect(item.normalizedTitle == "turkiye kanali")
    }

    @Test("M3UItem cleanTitle with custom normalizer")
    func itemCleanTitleWithCustomNormalizer() {
        let item = M3UItem(
            name: "BBC One HD",
            url: URL(string: "http://example.com")!
        )

        let normalizer = TitleNormalizer()
        #expect(item.cleanTitle(using: normalizer) == "BBC One")
    }

    // MARK: - Edge Cases

    @Test("Handle empty title")
    func handleEmptyTitle() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.normalize("") == "")
        #expect(normalizer.sanitize("") == "")
    }

    @Test("Handle title with only prefixes")
    func handleOnlyPrefixes() {
        let normalizer = TitleNormalizer()

        // When sanitized, should become empty or minimal
        #expect(normalizer.sanitize("TR:").trimmingCharacters(in: .whitespaces) == "")
    }

    @Test("Handle title with special characters")
    func handleSpecialCharacters() {
        let normalizer = TitleNormalizer()

        #expect(normalizer.normalize("BBC One & Two") == "bbc one & two")
        // ESPN+ is a valid channel name, + is only removed when preceded by space
        #expect(normalizer.sanitize("ESPN+") == "ESPN+")
        #expect(normalizer.sanitize("ESPN +") == "ESPN")
    }
}
