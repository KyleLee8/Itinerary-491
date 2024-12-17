import Foundation

class SearchHotelsAPI {
    static func searchHotels(geoId: String, checkIn: String, checkOut: String, completion: @escaping (Result<[HotelData], Error>) -> Void) {
        let apiKey = "d5c4af3fa3msh6a6267a04b4b0a8p16f7cejsnc366d9c069fa"
        let baseURL = "https://tripadvisor16.p.rapidapi.com/api/v1/hotels/searchHotels"
        
        // Construct the full URL
        guard var components = URLComponents(string: baseURL) else {
            debugLog("DEBUG: Invalid base URL")
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid base URL"])))
            }
            return
        }
        
        // Add query parameters
        components.queryItems = [
            URLQueryItem(name: "geoId", value: geoId),
            URLQueryItem(name: "checkIn", value: checkIn),
            URLQueryItem(name: "checkOut", value: checkOut),
            URLQueryItem(name: "pageNumber", value: "1"),
            URLQueryItem(name: "currencyCode", value: "USD")
        ]
        
        guard let url = components.url else {
            debugLog("DEBUG: Failed to construct URL with query parameters.")
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid query parameters"])))
            }
            return
        }
        
        // Setup the request
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.httpMethod = "GET"
        request.setValue("tripadvisor16.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        
        debugLog("DEBUG: Sending request to URL: \(url.absoluteString)")
        
        // Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            if let error = error {
                debugLog("DEBUG: Network error occurred: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Ensure data exists
            guard let data = data else {
                debugLog("DEBUG: No data received from API.")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from API"])))
                }
                return
            }
            
            // Debug log: Raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                debugLog("DEBUG: Raw JSON Response: \(jsonString)")
            }
            
            // Decode JSON
            do {
                // Decode JSON
                let apiResponse = try JSONDecoder().decode(HotelSearchResponse.self, from: data)
                
                // Safely unwrap the nested optionals
                guard let dataContainer = apiResponse.data,
                      let hotelData = dataContainer.data else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required data"])
                }
                
                // Ensure all `id` values are convertible to `Int`
                let hotelsWithValidIds = hotelData.filter { Int($0.id ?? "") != nil }
                
                debugLog("DEBUG: Successfully decoded response with \(hotelsWithValidIds.count) valid hotels.")
                
                // Pass the result to completion
                DispatchQueue.main.async {
                    completion(.success(hotelsWithValidIds))
                }
            } catch {
                debugLog("DEBUG: Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    debugLog("DEBUG: Raw JSON that caused error: \(jsonString)")
                }
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])))
                }
            }
        }
        task.resume()
    }
    
    private static func debugLog(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}

// MARK: - Models

/// Represents the API's overall response structure
/// Represents the API's overall response structure
struct HotelSearchResponse: Codable {
    let data: HotelSearchDataContainer?
    
    func withSafeDefaults() -> HotelSearchResponse {
        return HotelSearchResponse(
            data: data?.withSafeDefaults()
        )
    }
}

/// Represents the `data` field of the API response
struct HotelSearchDataContainer: Codable {
    let sortDisclaimer: String?
    let data: [HotelData]?
    
    func withSafeDefaults() -> HotelSearchDataContainer {
        return HotelSearchDataContainer(
            sortDisclaimer: sortDisclaimer ?? "No sort disclaimer available",
            data: data?.map { $0.withSafeDefaults() } ?? []
        )
    }
}

/// Represents a hotel item in the API's `data` array
struct HotelData: Codable, Identifiable {
    var id: String? // `id` is received as String from API
    let title: String?
    let priceForDisplay: String?
    let bubbleRating: BubbleRating?
    let secondaryInfo: String?
    
    // Convert `id` to Int if needed
    var intId: Int? {
        guard let id = id else { return nil }
        return Int(id)
    }

    func withSafeDefaults() -> HotelData {
        return HotelData(
            id: id ?? "0",
            title: title ?? "Unnamed Hotel",
            priceForDisplay: priceForDisplay ?? "N/A",
            bubbleRating: bubbleRating?.withSafeDefaults(),
            secondaryInfo: secondaryInfo ?? "No additional info"
        )
    }
}

/// Represents the bubble rating of a hotel
struct BubbleRating: Codable {
    let rating: Double? // Numeric rating
    let count: String? // Number of reviews as a string
    
    func withSafeDefaults() -> BubbleRating {
        return BubbleRating(
            rating: rating ?? 0.0,
            count: count ?? "0"
        )
    }
}
