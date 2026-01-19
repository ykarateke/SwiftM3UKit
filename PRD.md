```markdown
# Product Requirements Document (PRD)

## Proje Adı
**SwiftM3UKit**  
_(Geçici ad – dağıtım öncesi değiştirilebilir)_

## Doküman Versiyonu
v1.0

## Hazırlayan
Yasin Karateke

## Tarih
2026-01-19

---

## 1. Amaç (Purpose)

SwiftM3UKit, **IPTV odaklı M3U / EXTM3U playlist dosyalarının**:

- hızlı,
- bellek dostu,
- thread-safe,
- genişletilebilir

şekilde **parse edilmesini, ayrıştırılmasını ve yapılandırılmış veri modelleri halinde sunulmasını** sağlayan bir **Swift framework** olarak tasarlanacaktır.

Framework; iOS, tvOS ve macOS uygulamalarında sıkça karşılaşılan **UI donmaları, performans problemleri ve tutarsız M3U formatları** gibi sorunları çözmeyi hedefler.

---

## 2. Hedef Kitle (Target Audience)

### Birincil Kullanıcılar
- IPTV uygulaması geliştiren iOS / tvOS geliştiricileri
- Swift tabanlı medya platformları
- M3U ile çalışan kurumsal medya yazılımları

### İkincil Kullanıcılar
- Açık kaynak IPTV projeleri
- IPTV liste yöneticileri
- Test / analiz amaçlı M3U işleyen araçlar

---

## 3. Problem Tanımı (Problem Statement)

Swift ekosisteminde:

- IPTV’ye **özel ve olgun bir M3U parser bulunmamaktadır**
- Mevcut kütüphaneler ağırlıklı olarak **HLS / segment bazlı m3u8** formatına yöneliktir
- Regex tabanlı çözümler:
  - performanssızdır
  - debug edilmesi zordur
  - büyük playlist’lerde UI thread’i kilitler
- Dizi / sezon / bölüm ayrımı çoğu projede **manuel ve hataya açıktır**

Bu durum geliştiricilerin:
- her projede sıfırdan parser yazmasına,
- kararsız davranışlara,
- App Store red risklerine

neden olmaktadır.

---

## 4. Çözüm Tanımı (Proposed Solution)

SwiftM3UKit:

- IPTV EXTM3U formatını **native olarak anlayan**
- Satır bazlı **streaming parser**
- Lexer + Token mimarisi
- İçerik türü (Live / Movie / Series) sınıflandırması
- Basit ve temiz bir Public API

sunan **çekirdek bir Swift framework** olacaktır.

---

## 5. Kapsam (Scope)

### 5.1 Dahil Olan Özellikler (In-Scope)

- `.m3u` / `.m3u8` IPTV playlist parse
- `#EXTINF` attribute ayrıştırma:
  - `tvg-id`
  - `tvg-name`
  - `tvg-logo`
  - `group-title`
- Kanal / Film / Dizi sınıflandırması
- Sezon / bölüm tespiti (heuristic)
- Async / Await destekli parsing
- Büyük dosyalarda stabil çalışma
- Swift Package Manager (SPM) desteği

### 5.2 Hariç Olan Özellikler (Out-of-Scope)

- Video oynatma
- EPG XML parse
- UI bileşenleri
- Network download katmanı
- DRM veya stream doğrulama

---

## 6. Teknik Gereksinimler (Technical Requirements)

### Platform Desteği
- iOS 15+
- tvOS 15+
- macOS 12+

### Dil & Dağıtım
- Swift 5.9+
- Swift Package Manager

### Performans Gereksinimleri
- 100.000+ satırlık playlist dosyaları
- UI thread bloklanmadan parsing
- Düşük bellek tüketimi

---

## 7. Mimari Tasarım (Architecture)

### 7.1 Genel Katmanlar

```

Application Layer
↓
Public API (SwiftM3UKit)
↓
Parser / Lexer
↓
Content Classifier
↓
Data Models

````

### 7.2 Temel Bileşenler

#### Parser
- Async / Await tabanlı
- Streaming line reader
- Hata toleranslı yapı

#### Lexer
- Regex yerine token tabanlı ayrıştırma
- EXTINF + URL eşleşme mantığı

#### Classifier
- İçerik türü tespiti
- Heuristic algoritmalar

---

## 8. Veri Modelleri (Data Models)

### M3UItem (Temel Model)

Alanlar:
- name
- url
- group
- logo
- epgID
- contentType

### ContentType

- live
- movie
- series (season ve episode opsiyonel)

---

## 9. Public API Tasarımı

### Basit Kullanım

```swift
let parser = M3UParser()
let playlist = try await parser.parse(from: url)
````

### Erişim Noktaları

* `playlist.items`
* `playlist.channels`
* `playlist.movies`
* `playlist.series`

### Filtreleme Örneği

```swift
playlist.items.filter { $0.group == "TR | Spor" }
```

---

## 10. Hata Yönetimi (Error Handling)

* Bozuk EXTINF satırları atlanır
* Eksik URL içeren entry’ler discard edilir
* Parser crash etmez
* Hatalar açık error type’lar ile expose edilir

---

## 11. Güvenlik & App Store Uyumu

* Private API kullanımı yok
* Dynamic code execution yok
* Sandbox uyumlu dosya erişimi
* Kontrollü background thread kullanımı

---

## 12. Test Stratejisi

### Test Türleri

* Unit Tests (Parser, Lexer, Classifier)
* Edge-case M3U dosyaları
* Encoding testleri (UTF-8, Latin-1)
* Performans ve benchmark testleri

### Test Verileri

* Gerçek IPTV playlist’leri
* Bozuk ve eksik metadata içeren örnekler

---

## 13. Başarı Kriterleri (Success Metrics)

* UI donması olmadan parsing
* %95+ doğru içerik sınıflandırması
* Crash-free çalışma
* 5 satırdan kısa entegrasyon süresi

---

## 14. Riskler ve Önlemler

| Risk                                | Önlem                          |
| ----------------------------------- | ------------------------------ |
| M3U formatlarının standart dışılığı | Heuristic + toleranslı parsing |
| Büyük dosyalarda performans         | Streaming ve lazy parsing      |
| Yanlış sınıflandırma                | Modüler classifier mimarisi    |

---

## 15. Roadmap (v2+)

* Incremental / paginated parsing
* EPG XML entegrasyonu için hook
* Custom classifier injection
* Diff-based playlist update
* tvOS odaklı performans optimizasyonları

---

## 16. Açık Kaynak Stratejisi (Opsiyonel)

* MIT License
* GitHub üzerinde README + örnek projeler
* IPTV uygulamaları için referans implementation

---

## Sonuç

SwiftM3UKit, IPTV odaklı Swift uygulamaları için:

* sürdürülebilir,
* performanslı,
* App Store uyumlu

bir **çekirdek parsing çözümü** sunmayı hedefler.

```