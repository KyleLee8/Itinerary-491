import Foundation

class HotelAPI {
    static func searchHotels(locationQuery: String, completion: @escaping (Result<[HotelLocation], Error>) -> Void) {
        let apiKey = "d5c4af3fa3msh6a6267a04b4b0a8p16f7cejsnc366d9c069fa"
        let baseURL = "https://tripadvisor16.p.rapidapi.com/api/v1/hotels/searchLocation"
        
        // Construct the full URL
        guard let encodedQuery = locationQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?query=\(encodedQuery)") else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid query parameter"])))
            }
            return
        }
        
        // Setup the request
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.httpMethod = "GET"
        request.setValue("tripadvisor16.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        
        // Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Ensure data exists
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from API"])))
                }
                return
            }
            
            // Debug log: Raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(jsonString)")
            }
            
            // Decode JSON
            do {
                let apiResponse = try JSONDecoder().decode(HotelAPIResponse.self, from: data)
                
                // Check API status
                guard apiResponse.status else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: apiResponse.message])))
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(.success(apiResponse.data))
                }
            } catch {
                // Handle JSON decoding errors
                print("Decoding Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON that caused error: \(jsonString)")
                }
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])))
                }
            }
        }
        task.resume()
    }
}

// MARK: - Models

/// Represents the API's overall response structure
struct HotelAPIResponse: Codable {
    let status: Bool // Indicates whether the request was successful
    let message: String // Message about the request status
    let timestamp: Int // Server timestamp of the response
    let data: [HotelLocation] // Array of hotel locations
}

/// Represents a hotel location item in the API's `data` array
struct HotelLocation: Codable, Identifiable {
    var id: String { "\(geoId)" } // Unique identifier derived from geoId
    let title: String // Main title of the location
    let geoId: Int // Unique identifier for the location
    let documentId: String // Document reference ID
    let secondaryText: String // Additional description (e.g., region or country)
}
