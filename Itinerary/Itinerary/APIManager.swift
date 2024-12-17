import Foundation

// Vacation Location Response
struct VacationLocationResponse: Codable {
    let status: Bool
    let message: String
    let data: [VacationLocation]
}

struct VacationLocation: Codable {
    let geoId: Int
    let locationId: Int
    let localizedName: String
    let localizedAdditionalNames: String
    let locationV2: String
    let placeType: String
    let latitude: Double
    let longitude: Double
    let isGeo: Bool
    let thumbnail: Thumbnail

    struct Thumbnail: Codable {
        let photoSizeDynamic: PhotoSizeDynamic
    }

    struct PhotoSizeDynamic: Codable {
        let maxWidth: Int
        let maxHeight: Int
        let urlTemplate: String
    }
}

// Rental Search Response
struct RentalSearchResponse: Codable {
    let status: Bool
    let message: String
    let data: RentalSearchData
}

struct RentalSearchData: Codable {
    let rentals: RentalSearchResults
}

struct RentalSearchResults: Codable {
    let totalPages: Int
    let totalRentals: Int
    let rentals: [Rental]
}

struct Rental: Codable {
    let rentalId: String
    let name: String
    let rate: Rate?
    let rental: RentalDetails?
    let titleInfo: TitleInfo?
    var geoCoordinates: GeoCoordinates?
    var quickView: QuickView?
    let mostRecentReviews: [RecentReview]?
    let amenities: [Amenity]?

    // Custom Decoding Logic for GeoCoordinates
    struct GeoCoordinates: Codable {
            let lat: Double?
            let lng: Double?
        }

        struct QuickView: Codable {
            let address: String?
            let description: String?
            let rentalCategory: String?
        }

    struct Rate: Codable {
        let details: [RateDetail]?

        struct RateDetail: Codable {
            let type: String?
            let rate: RateAmount?

            struct RateAmount: Codable {
                let amount: Double?
                let currency: String?
                let amountUSD: Double?
            }
        }
    }

    struct RentalDetails: Codable {
        let name: String?
    }

    struct TitleInfo: Codable {
        let title: String?
        let bathCount: Int?
        let sleepCount: Int?
        let roomCount: Int?
        let averageRatingNumber: Double?
        let userReviewCount: Int?
    }

    struct RecentReview: Codable {
        let text: String?
        let rating: Int?
        let title: String?
    }

    struct Amenity: Codable {
        let key: String?
        let value: AmenityValue?
    }

    struct AmenityValue: Codable {
        let localizedText: String?
    }
}

// API Manager
class APIManager {
    static let shared = APIManager()

    private let baseURL = "https://tripadvisor16.p.rapidapi.com/api/v1/rentals"
    private let apiKey = "d5c4af3fa3msh6a6267a04b4b0a8p16f7cejsnc366d9c069fa"
    private let host = "tripadvisor16.p.rapidapi.com"

    // Fetch Vacation Locations
    func fetchVacationLocations(query: String, completion: @escaping (Result<[VacationLocation], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/searchLocation?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue(host, forHTTPHeaderField: "X-RapidAPI-Host")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let noDataError = NSError(domain: "API Error", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data received from API"])
                completion(.failure(noDataError))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(VacationLocationResponse.self, from: data)
                if decodedResponse.status {
                    completion(.success(decodedResponse.data))
                } else {
                    let apiError = NSError(domain: "API Error", code: 400, userInfo: [NSLocalizedDescriptionKey: decodedResponse.message])
                    completion(.failure(apiError))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Fetch Rentals
    func fetchRentals(
        geoId: Int,
        sortOrder: String = "POPULARITY",
        page: Int = 1,
        currencyCode: String = "USD",
        arrival: Date,
        departure: Date,
        completion: @escaping (Result<[Rental], Error>) -> Void
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let arrivalDate = dateFormatter.string(from: arrival)
        let departureDate = dateFormatter.string(from: departure)

        guard let url = URL(string: "\(baseURL)/rentalSearch?geoId=\(geoId)&sortOrder=\(sortOrder)&page=\(page)&currencyCode=\(currencyCode)&arrival=\(arrivalDate)&departure=\(departureDate)") else {
            let urlError = NSError(domain: "Invalid URL", code: 400, userInfo: nil)
            print("DEBUG: Invalid URL")
            completion(.failure(urlError))
            return
        }

        print("DEBUG: Making request to URL: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue(host, forHTTPHeaderField: "X-RapidAPI-Host")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: HTTP Response Status Code: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                let noDataError = NSError(domain: "API Error", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data received from API"])
                print("DEBUG: No data received from API")
                completion(.failure(noDataError))
                return
            }

            do {
                print("DEBUG: Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to String")")

                // Custom decoding logic
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let rawResponse = try decoder.decode(RentalSearchResponse.self, from: data)
                
                // Extract rentals array
                let rentals = rawResponse.data.rentals.rentals
                
                // Log decoded rentals for debugging
                print("DEBUG: Decoded Rentals: \(rentals)")

                // Pass the rentals to the completion handler
                completion(.success(rentals))
            } catch let DecodingError.keyNotFound(key, context) {
                print("DEBUG: Missing key '\(key.stringValue)' in JSON: \(context.debugDescription)")
                completion(.failure(NSError(domain: "DecodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing key '\(key.stringValue)' in JSON"])))
            } catch let DecodingError.typeMismatch(type, context) {
                print("DEBUG: Type mismatch for type '\(type)' in JSON: \(context.debugDescription)")
                completion(.failure(NSError(domain: "DecodingError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Type mismatch for type '\(type)' in JSON"])))
            } catch {
                print("DEBUG: Decoding error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}
