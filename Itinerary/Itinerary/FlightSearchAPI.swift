import Foundation

// Root object
struct FlightSearchAPIResponse: Codable {
    let status: Bool
    let message: String
    let timestamp: Int
    let data: FlightSearchData?
}

// Data object
struct FlightSearchData: Codable {
    let session: Session?
    let complete: Bool?
    let numOfFilters: Int?
    let totalNumResults: Int?
    let flights: [Flight]?
}

// Session object
struct Session: Codable {
    let searchHash: String?
    let pageLoadUid: String?
    let searchId: String?
    let filterSettings: FilterSettings?
}

// FilterSettings object
struct FilterSettings: Codable {
    let tt, aa, a, d: String?
    let ns, cos, fq, al, ft, sid, oc, plp, mc, pRange, da, ca: String?
}

// Flight object
struct Flight: Codable {
    let segments: [Segment]?
    let purchaseLinks: [PurchaseLink]?
    let itineraryTag: ItineraryTag?
}

// Segment object
struct Segment: Codable {
    let legs: [FlightLeg]?
    let layovers: [String]?
}

// FlightLeg object
struct FlightLeg: Codable {
    let originStationCode: String?
    let isDifferentOriginStation: Bool?
    let destinationStationCode: String?
    let isDifferentDestinationStation: Bool?
    let departureDateTime: String?
    let arrivalDateTime: String?
    let classOfService: String?
    let marketingCarrierCode: String?
    let operatingCarrierCode: String?
    let flightNumber: Int?
    let numStops: Int?
    let distanceInKM: Double?
    let isInternational: Bool?
    let operatingCarrier: Carrier?
    let marketingCarrier: Carrier?
}

// Carrier object
struct Carrier: Codable {
    let locationId: Int?
    let code: String?
    let logoUrl: String?
    let displayName: String?
}

// PurchaseLink object
struct PurchaseLink: Codable {
    let purchaseLinkId: String?
    let providerId: String?
    let partnerSuppliedProvider: PartnerSuppliedProvider?
    let commerceName: String?
    let currency: String?
    let totalPrice: Double?
    let url: String?
}

// PartnerSuppliedProvider object
struct PartnerSuppliedProvider: Codable {
    let id: String?
    let displayName: String?
    let logoUrl: String?
}

// ItineraryTag object
struct ItineraryTag: Codable {
    let tag: String?
    let type: String?
}

// FlightModel object to map the result
struct FlightModel: Hashable {
    let origin: String
    let destination: String
    let departure: String
    let arrival: String
    let classOfService: String
    let carrierName: String
    let carrierLogo: String
    let stops: Int
    let distance: Double
    let totalPrice: Double
    let purchaseLink: String
    let itineraryTag: String

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(origin)
        hasher.combine(destination)
        hasher.combine(departure)
        hasher.combine(arrival)
        hasher.combine(totalPrice)
    }

    static func == (lhs: FlightModel, rhs: FlightModel) -> Bool {
        return lhs.origin == rhs.origin &&
               lhs.destination == rhs.destination &&
               lhs.departure == rhs.departure &&
               lhs.arrival == rhs.arrival &&
               lhs.totalPrice == rhs.totalPrice
    }
}

// API Call Logic
class FlightSearchAPI {
    static func searchFlights(
        originCode: String,
        destinationCode: String,
        travelDate: String,
        returnDate: String? = nil, // Optional return date for round trips
        itineraryType: String = "ONE_WAY",
        sortOrder: String = "ML_BEST_VALUE",
        numAdults: Int = 1,
        numSeniors: Int = 0,
        classOfService: String = "ECONOMY",
        pageNumber: Int = 1,
        includeNearby: Bool = false,
        nonstop: Bool = false,
        completion: @escaping (Result<([FlightModel], [FlightModel]?), Error>) -> Void
    ) {
        let apiKey = "d5c4af3fa3msh6a6267a04b4b0a8p16f7cejsnc366d9c069fa"
        let apiHost = "tripadvisor16.p.rapidapi.com"

        print("DEBUG: Starting flight search for \(originCode) → \(destinationCode) on \(travelDate)")

        // Outbound API call
        let outboundRequest = createRequest(
            origin: originCode,
            destination: destinationCode,
            date: travelDate,
            itineraryType: itineraryType,
            sortOrder: sortOrder,
            numAdults: numAdults,
            numSeniors: numSeniors,
            classOfService: classOfService,
            pageNumber: pageNumber,
            includeNearby: includeNearby,
            nonstop: nonstop,
            apiKey: apiKey,
            apiHost: apiHost
        )

        print("DEBUG: Outbound API Request: \(outboundRequest.url?.absoluteString ?? "Invalid URL")")

        let outboundTask = URLSession.shared.dataTask(with: outboundRequest) { data, response, error in
            if let error = error {
                print("DEBUG: Error during API call: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                print("DEBUG: No data received from the API.")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from API"])))
                }
                return
            }

            if let rawJSON = String(data: data, encoding: .utf8) {
                print("DEBUG: Raw JSON Response: \(rawJSON)")
            }

            do {
                let apiResponse = try JSONDecoder().decode(FlightSearchAPIResponse.self, from: data)
                print("DEBUG: Successfully decoded response.")
                let outboundFlights = mapFlights(from: apiResponse)

                // Check for round-trip
                if itineraryType == "ROUND_TRIP", let returnDate = returnDate {
                    print("DEBUG: Round trip detected. Fetching return flights for \(destinationCode) → \(originCode) on \(returnDate)")
                    // Return API call (not shown for brevity)
                } else {
                    print("DEBUG: Outbound flights only.")
                    DispatchQueue.main.async {
                        completion(.success((outboundFlights, nil)))
                    }
                }
            } catch {
                print("DEBUG: Error decoding JSON response: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Failed JSON String: \(jsonString)")
                }
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        outboundTask.resume()
    }

    private static func createRequest(
        origin: String,
        destination: String,
        date: String,
        itineraryType: String,
        sortOrder: String,
        numAdults: Int,
        numSeniors: Int,
        classOfService: String,
        pageNumber: Int,
        includeNearby: Bool,
        nonstop: Bool,
        apiKey: String,
        apiHost: String
    ) -> URLRequest {
        var components = URLComponents(string: "https://tripadvisor16.p.rapidapi.com/api/v1/flights/searchFlights")!
        components.queryItems = [
            URLQueryItem(name: "sourceAirportCode", value: origin),
            URLQueryItem(name: "destinationAirportCode", value: destination),
            URLQueryItem(name: "date", value: date),
            URLQueryItem(name: "itineraryType", value: itineraryType),
            URLQueryItem(name: "sortOrder", value: sortOrder),
            URLQueryItem(name: "numAdults", value: "\(numAdults)"),
            URLQueryItem(name: "numSeniors", value: "\(numSeniors)"),
            URLQueryItem(name: "classOfService", value: classOfService),
            URLQueryItem(name: "pageNumber", value: "\(pageNumber)"),
            URLQueryItem(name: "nearby", value: includeNearby ? "yes" : "no"),
            URLQueryItem(name: "nonstop", value: nonstop ? "yes" : "no"),
            URLQueryItem(name: "currencyCode", value: "USD")
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 60
        request.httpMethod = "GET"
        request.setValue(apiHost, forHTTPHeaderField: "X-RapidAPI-Host")
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        print("DEBUG: Generated API Request URL: \(components.url?.absoluteString ?? "Invalid URL")")
        return request
    }

    private static func mapFlights(from response: FlightSearchAPIResponse) -> [FlightModel] {
        guard let flights = response.data?.flights else {
            print("DEBUG: No flights found in the response.")
            return []
        }

        return flights.compactMap { flight in
            guard let leg = flight.segments?.first?.legs?.first,
                  let origin = leg.originStationCode,
                  let destination = leg.destinationStationCode,
                  let departure = leg.departureDateTime,
                  let arrival = leg.arrivalDateTime,
                  let price = flight.purchaseLinks?.first?.totalPrice else {
                print("DEBUG: Missing critical data for a flight. Skipping entry.")
                return nil
            }

            return FlightModel(
                origin: origin,
                destination: destination,
                departure: departure,
                arrival: arrival,
                classOfService: leg.classOfService ?? "Unknown",
                carrierName: leg.marketingCarrier?.displayName ?? "Unknown",
                carrierLogo: leg.marketingCarrier?.logoUrl ?? "",
                stops: leg.numStops ?? 0,
                distance: leg.distanceInKM ?? 0.0,
                totalPrice: price,
                purchaseLink: flight.purchaseLinks?.first?.url ?? "",
                itineraryTag: flight.itineraryTag?.tag ?? ""
            )
        }
    }
}
