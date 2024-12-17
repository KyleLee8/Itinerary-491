import Foundation

// MARK: - API3 Namespace
enum API3 {
    struct RestaurantDetailsResponse: Codable {
        let status: Bool
        let message: String?
        let timestamp: Int
        let data: RestaurantDetailsData?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            status = try container.decodeIfPresent(Bool.self, forKey: .status) ?? false
            message = try container.decodeIfPresent(String.self, forKey: .message) ?? "No message available"
            timestamp = try container.decodeIfPresent(Int.self, forKey: .timestamp) ?? 0
            data = try container.decodeIfPresent(RestaurantDetailsData.self, forKey: .data)
        }
    }

    struct RestaurantDetailsData: Codable {
        let about: AboutSection?
        let openHours: OpenHoursSection?
        let heroMedia: HeroMediaSection?
        let overview: OverviewSection?
        let reviews: ReviewsSection?
        let qA: QASection?
        let alsoPopularWithTravellers: PopularWithTravellersSection?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            about = try container.decodeIfPresent(AboutSection.self, forKey: .about)
            openHours = try container.decodeIfPresent(OpenHoursSection.self, forKey: .openHours)
            heroMedia = try container.decodeIfPresent(HeroMediaSection.self, forKey: .heroMedia)
            overview = try container.decodeIfPresent(OverviewSection.self, forKey: .overview)
            reviews = try container.decodeIfPresent(ReviewsSection.self, forKey: .reviews)
            qA = try container.decodeIfPresent(QASection.self, forKey: .qA)
            alsoPopularWithTravellers = try container.decodeIfPresent(PopularWithTravellersSection.self, forKey: .alsoPopularWithTravellers)
        }
    }

    struct AboutSection: Codable {
        let sectionTitle: LocalizedString?
        let content: [ContentItem]?

        struct ContentItem: Codable {
            let title: LocalizedString?
            let list: [LocalizedString]?
        }
    }

    struct OpenHoursSection: Codable {
        let hoursForDays: [HoursForDay]?

        struct HoursForDay: Codable {
            let day: LocalizedString?
            let localizedIntervals: [LocalizedString]?
        }
    }

    struct HeroMediaSection: Codable {
        let photoCount: Int?
        let media: [MediaItem]?

        struct MediaItem: Codable {
            let sizes: [MediaSize]?
        }
    }

    struct OverviewSection: Codable {
        let name: String?
        let rating: Double?
        let numberReviews: Int?
        let tagsV2: LocalizedString?
    }

    struct ReviewsSection: Codable {
        let tabTitle: LocalizedString?
        let content: [ReviewContent]?

        struct ReviewContent: Codable {
            let htmlTitle: LocalizedString?
            let htmlText: LocalizedString?
        }
    }

    struct QASection: Codable {
        let tabTitle: LocalizedString?
        let content: [QAContent]?

        struct QAContent: Codable {
            let question: LocalizedString?
            let answer: LocalizedString?
        }
    }

    struct PopularWithTravellersSection: Codable {
        let wideCardsCarouselTitle: LocalizedString?
        let wideCardsCarouselContent: [WideCard]?

        struct WideCard: Codable {
            let cardTitle: LocalizedString?
        }
    }

    struct LocalizedString: Codable {
        let text: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            text = try container.decodeIfPresent(String.self, forKey: .text) ?? "N/A"
        }
    }

    struct MediaSize: Codable {
        let maxWidth: Int?
        let maxHeight: Int?
        let url: String?
    }
}



// MARK: - API Class for API3
class RestaurantDetailsAPI {
    static let apiKey = "d5c4af3fa3msh6a6267a04b4b0a8p16f7cejsnc366d9c069fa"
    static let apiHost = "tripadvisor16.p.rapidapi.com"

    static func fetchRestaurantDetails(restaurantID: String, completion: @escaping (Result<API3.RestaurantDetailsResponse, RestaurantDetailsError>) -> Void) {
        let apiURL = "https://tripadvisor16.p.rapidapi.com/api/v1/restaurant/getRestaurantDetailsV2?restaurantsId=\(restaurantID)&currencyCode=USD"

        guard let url = URL(string: apiURL) else {
            print("[DEBUG] Invalid URL: \(apiURL)")
            completion(.failure(.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.httpMethod = "GET"

        print("[DEBUG] Sending request to URL: \(apiURL)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[DEBUG] Request failed with error: \(error.localizedDescription)")
                completion(.failure(.requestFailed(error.localizedDescription)))
                return
            }

            guard let data = data else {
                print("[DEBUG] No data received from API.")
                completion(.failure(.invalidData))
                return
            }

            // Print raw JSON for debugging purposes
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Raw JSON received: \(jsonString)")
            } else {
                print("[DEBUG] Unable to parse JSON as String.")
            }

            do {
                let decodedResponse = try JSONDecoder().decode(API3.RestaurantDetailsResponse.self, from: data)
                print("[DEBUG] Successfully decoded response: \(decodedResponse)")
                completion(.success(decodedResponse))
            } catch let decodeError {
                print("[DEBUG] Decoding error: \(decodeError.localizedDescription)")
                print("[DEBUG] Failed JSON: \(String(data: data, encoding: .utf8) ?? "No JSON")")
                completion(.failure(.invalidResponse))
            }
        }.resume()
    }
}

// MARK: - Error Enum for API3
enum RestaurantDetailsError: Error {
    case invalidResponse
    case invalidData
    case requestFailed(String)
}
