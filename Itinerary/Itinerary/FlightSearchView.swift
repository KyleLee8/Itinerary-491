import SwiftUI

struct FlightSearchView: View {
    @Binding var origin: AirportAPI.Airport?
    @Binding var destination: AirportAPI.Airport?

    @State private var flights: [FlightModel] = []
    @State private var outboundFlights: [FlightModel] = []
    @State private var returnFlights: [FlightModel] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var travelDate: Date = Date()
    @State private var returnDate: Date = Date()
    @State private var itineraryType: String = "ONE_WAY"
    @State private var numAdults: Int = 1
    @State private var numSeniors: Int = 0
    @State private var classOfService: String = "ECONOMY"
    @State private var includeNearbyAirports: Bool = false
    @State private var preferNonstop: Bool = false
    @State private var sortOrder: String = "PRICE"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let origin = origin, let destination = destination {
                        // Route Details
                        Group {
                            Text("From: \(origin.name) (\(origin.airportCode))")
                                .font(.headline)
                            Text("To: \(destination.name) (\(destination.airportCode))")
                                .font(.headline)
                        }
                        .padding(.horizontal)

                        // Date Picker
                        DatePicker("Travel Date", selection: $travelDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding(.horizontal)

                        // Return Date Picker (for Round Trip)
                        if itineraryType == "ROUND_TRIP" {
                            DatePicker("Return Date", selection: $returnDate, displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding(.horizontal)
                        }

                        // Itinerary and Passenger Settings
                        Group {
                            Picker("Itinerary Type", selection: $itineraryType) {
                                Text("One Way").tag("ONE_WAY")
                                Text("Round Trip").tag("ROUND_TRIP")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)

                            Stepper("Number of Adults: \(numAdults)", value: $numAdults, in: 1...10)
                                .padding(.horizontal)

                            Stepper("Number of Seniors: \(numSeniors)", value: $numSeniors, in: 0...10)
                                .padding(.horizontal)

                            Picker("Class of Service", selection: $classOfService) {
                                Text("Economy").tag("ECONOMY")
                                Text("Business").tag("BUSINESS")
                                Text("First Class").tag("FIRST_CLASS")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }

                        // Sort Order Picker
                        Picker("Sort Order", selection: $sortOrder) {
                            Text("Price").tag("PRICE")
                            Text("Best Value").tag("ML_BEST_VALUE")
                            Text("Duration").tag("DURATION")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        // Additional Preferences
                        Group {
                            Toggle("Include Nearby Airports", isOn: $includeNearbyAirports)
                                .padding(.horizontal)

                            Toggle("Prefer Nonstop Flights", isOn: $preferNonstop)
                                .padding(.horizontal)
                        }

                        // Search Button
                        Button(action: {
                            print("DEBUG: Starting search with origin \(origin.airportCode) and destination \(destination.airportCode)")
                            searchFlights()
                        }) {
                            Text("Search Flights")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }

                        // Error Message and Retry Button
                        if let errorMessage = errorMessage {
                            VStack {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()

                                Button(action: {
                                    // Retry search after error
                                    print("DEBUG: Retrying flight search...")
                                    searchFlights()
                                }) {
                                    Text("Retry")
                                        .font(.headline)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // Loading Indicator
                        if isLoading {
                            VStack {
                                ProgressView("Loading flights...")
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    .padding()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.white.opacity(0.8)) // Optional: translucent background
                            .cornerRadius(10)
                            .padding()
                        }

                        // Flight Results - Display Multiple Flights
                        if !flights.isEmpty {
                            if itineraryType == "ROUND_TRIP" {
                                Text("Outbound Flights")
                                    .font(.headline)
                                    .padding(.horizontal)

                                LazyVStack {
                                    ForEach(flights.filter { $0.origin == origin.airportCode }, id: \.self) { flight in
                                        FlightRowView(flight: flight)
                                    }
                                }

                                Text("Return Flights")
                                    .font(.headline)
                                    .padding(.horizontal)

                                LazyVStack {
                                    ForEach(flights.filter { $0.origin == destination.airportCode }, id: \.self) { flight in
                                        FlightRowView(flight: flight)
                                    }
                                }
                            } else {
                                LazyVStack {
                                    ForEach(flights, id: \.self) { flight in
                                        FlightRowView(flight: flight)
                                    }
                                }
                            }
                        }
                    } else {
                        // Prompt to Select Airports
                        Text("Please select departure and arrival airports.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .navigationTitle("Flight Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func searchFlights() {
        guard let originCode = origin?.airportCode, let destinationCode = destination?.airportCode else {
            errorMessage = "Please select valid airports."
            print("DEBUG: Error - Invalid airport selection.")
            return
        }

        isLoading = true
        errorMessage = nil
        outboundFlights = [] // Resetting outbound flights
        returnFlights = []   // Resetting return flights
        flights = []         // Clear the combined flight results

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: travelDate)
        let formattedReturnDate = dateFormatter.string(from: returnDate)

        print("DEBUG: Searching flights for \(originCode) to \(destinationCode) on \(formattedDate)")

        // Fetch outbound flights
        FlightSearchAPI.searchFlights(
            originCode: originCode,
            destinationCode: destinationCode,
            travelDate: formattedDate,
            itineraryType: "ONE_WAY", // Outbound leg
            sortOrder: sortOrder,
            numAdults: numAdults,
            numSeniors: numSeniors,
            classOfService: classOfService,
            includeNearby: includeNearbyAirports,
            nonstop: preferNonstop
        ) { outboundResult in
            DispatchQueue.main.async {
                self.isLoading = false
                switch outboundResult {
                case .success(let fetchedOutboundFlights):
                    self.outboundFlights = fetchedOutboundFlights.0
                    print("DEBUG: Outbound flights found: \(self.outboundFlights.count)")

                    // Fetch return flights if round trip
                    if self.itineraryType == "ROUND_TRIP" {
                        print("DEBUG: Searching return flights for \(destinationCode) to \(originCode) on \(formattedReturnDate)")
                        FlightSearchAPI.searchFlights(
                            originCode: destinationCode,
                            destinationCode: originCode,
                            travelDate: formattedReturnDate,
                            itineraryType: "ONE_WAY", // Return leg
                            sortOrder: sortOrder,
                            numAdults: numAdults,
                            numSeniors: numSeniors,
                            classOfService: classOfService,
                            includeNearby: includeNearbyAirports,
                            nonstop: preferNonstop
                        ) { returnResult in
                            DispatchQueue.main.async {
                                switch returnResult {
                                case .success(let fetchedReturnFlights):
                                    self.returnFlights = fetchedReturnFlights.0
                                    print("DEBUG: Return flights found: \(self.returnFlights.count)")
                                    self.flights = self.outboundFlights + self.returnFlights
                                case .failure(let error):
                                    print("DEBUG: Error fetching return flights: \(error.localizedDescription)")
                                    self.errorMessage = "Error fetching return flights: \(error.localizedDescription)"
                                }
                            }
                        }
                    } else {
                        self.flights = self.outboundFlights
                    }

                case .failure(let error):
                    print("DEBUG: Error fetching outbound flights: \(error.localizedDescription)")
                    self.errorMessage = "Error fetching outbound flights: \(error.localizedDescription)"
                }
            }
        }
    }
}


struct FlightRowView: View {
    let flight: FlightModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("From: \(flight.origin) → To: \(flight.destination)")
                .font(.headline)

            HStack {
                Text("Departure: \(flight.departure)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Arrival: \(flight.arrival)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("Class: \(flight.classOfService)")
                .font(.subheadline)
                .foregroundColor(.blue)

            HStack {
                if !flight.carrierLogo.isEmpty {
                    AsyncImage(url: URL(string: flight.carrierLogo)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }
                Text("Carrier: \(flight.carrierName)")
                    .font(.subheadline)
                    .foregroundColor(.purple)
            }

            Text("Price: \(flight.totalPrice, specifier: "%.2f") USD")
                .font(.subheadline)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
