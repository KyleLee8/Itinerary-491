import Foundation

class AirportAPI {
    static func searchAirports(query: String, completion: @escaping (Result<[Airport], Error>) -> Void) {
        let apiKey = "d5c4af3fa3msh6a6267a04b4b0a8p16f7cejsnc366d9c069fa"
        let apiURL = "https://tripadvisor16.p.rapidapi.com/api/v1/flights/searchAirport?query=\(query)"
        
        guard let url = URL(string: apiURL) else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            }
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.httpMethod = "GET"
        request.setValue("tripadvisor16.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")

        print("DEBUG: Sending API Request to: \(apiURL)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Network Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                print("DEBUG: No data received from API")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from API"])))
                }
                return
            }

            print("DEBUG: Raw JSON Response: \(String(data: data, encoding: .utf8) ?? "No data")")

            do {
                let apiResponse = try JSONDecoder().decode(AirportAPIResponse.self, from: data)
                print("DEBUG: Decoded API Response: \(apiResponse)")

                // Parse both parent-level and child-level data
                var airports: [Airport] = []
                for airportData in apiResponse.data {
                    // Add the parent airport
                    if let details = airportData.details {
                        let coordinates = details.coords ?? "N/A"
                        airports.append(Airport(
                            name: airportData.name,
                            airportCode: airportData.airportCode ?? "N/A",
                            coordinates: coordinates,
                            shortName: details.shortName ?? "N/A",
                            parentName: details.parent_name ?? "N/A",
                            grandparentName: details.grandparent_name ?? "N/A"
                        ))
                        print("DEBUG: Mapped Parent Airport - Name: \(airportData.name), Code: \(airportData.airportCode ?? "N/A"), Coordinates: \(coordinates)")
                    }

                    // Add the child airports
                    if let children = airportData.children {
                        for child in children {
                            if let details = child.details {
                                let coordinates = details.coords ?? "N/A"
                                airports.append(Airport(
                                    name: child.name,
                                    airportCode: child.airportCode ?? "N/A",
                                    coordinates: coordinates,
                                    shortName: details.shortName ?? "N/A",
                                    parentName: details.parent_name ?? "N/A",
                                    grandparentName: details.grandparent_name ?? "N/A"
                                ))
                                print("DEBUG: Mapped Child Airport - Name: \(child.name), Code: \(child.airportCode ?? "N/A"), Coordinates: \(coordinates)")
                            }
                        }
                    }
                }

                DispatchQueue.main.async {
                    print("DEBUG: Final Mapped Airports: \(airports)")
                    completion(.success(airports))
                }
            } catch {
                print("DEBUG: Decoding Error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }

    // Models for the API response
    struct AirportAPIResponse: Codable {
        let data: [AirportData]
    }

    struct AirportData: Codable {
        let name: String
        let details: AirportDetails?
        let children: [ChildAirport]?
        let airportCode: String?
    }

    struct AirportDetails: Codable {
        let coords: String?
        let shortName: String?
        let parent_name: String?
        let grandparent_name: String?
    }

    struct ChildAirport: Codable {
        let name: String
        let details: AirportDetails?
        let airportCode: String?
    }

    // Simplified Airport Model
    struct Airport: Identifiable {
        var id = UUID()
        var name: String
        var airportCode: String
        var coordinates: String
        var shortName: String
        var parentName: String
        var grandparentName: String
    }
}

