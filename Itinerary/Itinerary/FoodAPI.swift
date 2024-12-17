import Foundation

// MARK: - API Class
class RestaurantAPI {
    static func getRestaurants(locationQuery: String, page: Int = 1, completion: @escaping (Result<[API1.DetailedRestaurant], Error>) -> Void) {
        let apiKey = "d5c4af3fa3msh6a6267a04b4b0a8p16f7cejsnc366d9c069fa" // Replace with your actual API key
        let apiURL = "https://tripadvisor16.p.rapidapi.com/api/v1/restaurant/searchLocation?query=\(locationQuery)&page=\(page)"

        // Debug: Print API URL
        print("[DEBUG] API URL: \(apiURL)")

        guard let url = URL(string: apiURL) else {
            print("[DEBUG] Invalid URL")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15 // 15 seconds timeout
        request.httpMethod = "GET"
        request.setValue("tripadvisor16.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")

        // Debug: Print request headers
        print("[DEBUG] Request Headers: \(request.allHTTPHeaderFields ?? [:])")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Debug: Print error details
                print("[DEBUG] Error during API call: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                // Debug: Print HTTP response status code
                print("[DEBUG] HTTP Response Status Code: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                print("[DEBUG] No data received from API")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from API"])))
                return
            }

            // Debug: Print raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Raw JSON Response: \(jsonString)")
            }

            do {
                // Attempt to decode the API response
                let apiResponse = try JSONDecoder().decode(API1.APIResponse.self, from: data)

                // Debug: Print number of restaurants received
                print("[DEBUG] Number of restaurants received: \(apiResponse.data.count)")

                let detailedRestaurants = apiResponse.data.map { restaurantData -> API1.DetailedRestaurant in
                    return API1.DetailedRestaurant(
                        locationId: restaurantData.locationId,
                        name: restaurantData.localizedName,
                        latitude: restaurantData.latitude,
                        longitude: restaurantData.longitude,
                        imageUrl: restaurantData.thumbnail?.photoSizeDynamic?.urlTemplate?
                            .replacingOccurrences(of: "{width}", with: "300")
                            .replacingOccurrences(of: "{height}", with: "200") ?? ""
                    )
                }

                // Debug: Print detailed restaurants array
                print("[DEBUG] Parsed Detailed Restaurants: \(detailedRestaurants)")

                completion(.success(detailedRestaurants))
            } catch {
                // Debug: Print decoding error details
                print("[DEBUG] Decoding error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

// MARK: - Models for API1
enum API1 {
    struct APIResponse: Codable {
        let status: Bool
        let message: String
        let timestamp: Int
        let data: [RestaurantData]
    }

    struct RestaurantData: Codable {
        let locationId: Int
        let localizedName: String
        let averageRating: Double?
        let userReviewCount: Int?
        let priceTag: String?
        let currentOpenStatusText: String?
        let latitude: Double
        let longitude: Double
        let thumbnail: Thumbnail?
    }

    struct Thumbnail: Codable {
        let photoSizeDynamic: PhotoSizeDynamic?
    }

    struct PhotoSizeDynamic: Codable {
        let urlTemplate: String?
    }

    struct DetailedRestaurant: Identifiable, Equatable {
        var id = UUID()
        var locationId: Int
        var name: String
        var latitude: Double
        var longitude: Double
        var imageUrl: String

        static func == (lhs: DetailedRestaurant, rhs: DetailedRestaurant) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.locationId == rhs.locationId &&
                   lhs.name == rhs.name &&
                   lhs.latitude == rhs.latitude &&
                   lhs.longitude == rhs.longitude &&
                   lhs.imageUrl == rhs.imageUrl
        }
    }
}
