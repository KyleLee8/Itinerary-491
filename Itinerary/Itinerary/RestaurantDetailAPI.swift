import Foundation

// MARK: - API2 Namespace
enum API2 {
    // Top-level response
    struct DetailedAPIResponse: Codable {
        let status: Bool
        let message: String
        let timestamp: Int
        let data: DataContainer
    }

    // Data container for the restaurant list
    struct DataContainer: Codable {
        let totalRecords: Int
        let totalPages: Int
        let data: [DetailedRestaurantData]
    }

    // Individual restaurant data
    struct DetailedRestaurantData: Identifiable, Codable {
        let id = UUID() // For Identifiable
        let restaurantsId: String
        let locationId: Int
        let name: String
        let averageRating: Double?
        let userReviewCount: Int?
        let currentOpenStatusCategory: String?
        let currentOpenStatusText: String?
        let priceTag: String?
        let hasMenu: Bool?
        let menuUrl: String?
        let isDifferentGeo: Bool?
        let parentGeoName: String?
        let distanceTo: Double? // Nullable in JSON
        let awardInfo: AwardInfo?
        let isLocalChefItem: Bool?
        let isPremium: Bool?
        let isStoryboardPublished: Bool?
        let establishmentTypeAndCuisineTags: [String]?
        let offers: OffersContainer?
        let heroImgUrl: String?
        let heroImgRawHeight: Int?
        let heroImgRawWidth: Int?
        let squareImgUrl: String?
        let squareImgRawLength: Int?
        let thumbnail: ThumbnailContainer?
        let reviewSnippets: ReviewSnippetsContainer?
        let latitude: Double?
        let longitude: Double?

    }

    // Award info container
    struct AwardInfo: Codable {
        let year: Int?
        let awardType: String?
    }

    // Offers container
    struct OffersContainer: Codable {
        let hasDelivery: Bool?
        let hasReservation: Bool?
        let slot1Offer: OfferDetails?
        let slot2Offer: OfferDetails?
        let restaurantSpecialOffer: OfferDetails?
    }

    // Offer details
    struct OfferDetails: Codable {
        let providerId: String?
        let provider: String?
        let providerDisplayName: String?
        let buttonText: String?
        let offerURL: String?
        let logoUrl: String?
        let trackingEvent: String?
        let canProvideTimeslots: Bool?
        let canLockTimeslots: Bool?
        let timeSlots: [String]?
    }

    // Thumbnail container
    struct ThumbnailContainer: Codable {
        let photo: PhotoContainer?
    }

    // Photo container
    struct PhotoContainer: Codable {
        let photoSizeDynamic: PhotoSizeDynamic?
    }

    // Photo size details
    struct PhotoSizeDynamic: Codable {
        let urlTemplate: String?
        let maxHeight: Int?
        let maxWidth: Int?
    }

    // Review snippets container
    struct ReviewSnippetsContainer: Codable {
        let reviewSnippetsList: [ReviewSnippet]?
    }

    // Review snippet details
    struct ReviewSnippet: Codable {
        let reviewText: String?
        let reviewUrl: String?
    }
}

// MARK: - API Class for API2
class DetailedRestaurantAPI {
    static let apiKey = "d5c4af3fa3msh6a6267a04b4b0a8p16f7cejsnc366d9c069fa"
    static let apiHost = "tripadvisor16.p.rapidapi.com"

    static func fetchDetailedRestaurants(locationId: Int, completion: @escaping (Result<[API2.DetailedRestaurantData], DetailedRestaurantError>) -> Void) {
        let apiURL = "https://tripadvisor16.p.rapidapi.com/api/v1/restaurant/searchRestaurants?locationId=\(locationId)"

        guard let url = URL(string: apiURL) else {
            completion(.failure(.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error.localizedDescription)))
                return
            }

            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(API2.DetailedAPIResponse.self, from: data)
                completion(.success(decodedResponse.data.data))
            } catch let decodeError {
                print("[DEBUG] Decoding error: \(decodeError.localizedDescription)")
                print("[DEBUG] Failed JSON: \(String(data: data, encoding: .utf8) ?? "No JSON")")
                completion(.failure(.invalidResponse))
            }
        }.resume()
    }
}

// MARK: - Error Enum for API2
enum DetailedRestaurantError: Error {
    case invalidResponse
    case invalidData
    case requestFailed(String)
}
