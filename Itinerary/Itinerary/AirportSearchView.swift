import SwiftUI

struct AirportSearchView: View {
    @State private var airports: [AirportAPI.Airport] = []
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var rawJsonResponse: String? = nil
    @Binding var selectedOrigin: AirportAPI.Airport?
    @Binding var selectedDestination: AirportAPI.Airport?
    @State private var isSelectingOrigin = true
    @State private var navigateToFlightSearch = false

    var body: some View {
        VStack {
            // Search Bar with Clear Button
            HStack {
                TextField("Search for Airports", text: $searchQuery)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        Button(action: {
                            searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        .opacity(searchQuery.isEmpty ? 0 : 1),
                        alignment: .trailing
                    )
            }
            .padding(.horizontal)

            // Buttons for Search and Cancel
            HStack {
                Button(action: {
                    print("DEBUG: Starting search with query: \(searchQuery)")
                    searchAirports()
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search Airports")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(searchQuery.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(searchQuery.isEmpty)

                if !isSelectingOrigin {
                    Button(action: resetSelection) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Cancel")
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)

            // Loading Indicator with Placeholder
            if isLoading {
                VStack {
                    ProgressView("Loading...")
                        .padding()
                    // Placeholder for skeleton view
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 50)
                            .padding(.horizontal)
                    }
                }
            }

            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            // Display Airport Results
            if !isLoading && airports.isEmpty && errorMessage == nil {
                Text("No airports found for the entered query.")
                    .font(.headline)
                    .padding()
            } else {
                List(airports) { airport in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(airport.name)
                                .font(.headline)
                            Text("Code: \(airport.airportCode.isEmpty ? "Unavailable" : airport.airportCode)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "airplane")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(selectedOrigin?.id == airport.id || selectedDestination?.id == airport.id ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                    .onTapGesture {
                        handleAirportSelection(airport)
                    }
                }
            }

            // Navigation Link to FlightSearchView
            NavigationLink(
                destination: FlightSearchView(
                    origin: $selectedOrigin,
                    destination: $selectedDestination
                ),
                isActive: $navigateToFlightSearch
            ) {
                EmptyView()
            }
        }
        .navigationTitle(isSelectingOrigin ? "Select Departure" : "Select Arrival")
        .animation(.easeInOut, value: isLoading) // Add animation
    }

    private func searchAirports() {
        isLoading = true
        errorMessage = nil
        airports = []
        rawJsonResponse = nil

        AirportAPI.searchAirports(query: searchQuery) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedAirports):
                    print("DEBUG: Search completed. Fetched Airports: \(fetchedAirports)")
                    if fetchedAirports.isEmpty {
                        errorMessage = "No airports found for the query: \(searchQuery)."
                    } else {
                        airports = fetchedAirports
                    }
                case .failure(let error):
                    print("DEBUG: Error fetching airports: \(error.localizedDescription)")
                    errorMessage = "Error fetching airports: \(error.localizedDescription)"
                }
            }
        }
    }

    private func handleAirportSelection(_ airport: AirportAPI.Airport) {
        if isSelectingOrigin {
            selectedOrigin = airport
            print("DEBUG: Selected Origin: \(airport.airportCode)")
            isSelectingOrigin = false // Switch to selecting arrival
        } else {
            selectedDestination = airport
            print("DEBUG: Selected Destination: \(airport.airportCode)")
            navigateToFlightSearch = true // Navigate to FlightSearchView
        }
    }

    private func resetSelection() {
        isSelectingOrigin = true
        selectedOrigin = nil
        selectedDestination = nil
        print("DEBUG: Selection reset. Back to selecting departure.")
    }
}

// PreviewProvider for Testing
struct AirportSearchView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var selectedOrigin: AirportAPI.Airport? = AirportAPI.Airport(
            id: UUID(),
            name: "Chhatrapati Shivaji Maharaj International Airport",
            airportCode: "BOM",
            coordinates: "19.0896° N, 72.8656° E",
            shortName: "Mumbai Airport",
            parentName: "Mumbai",
            grandparentName: "Maharashtra"
        )

        @State private var selectedDestination: AirportAPI.Airport? = AirportAPI.Airport(
            id: UUID(),
            name: "Indira Gandhi International Airport",
            airportCode: "DEL",
            coordinates: "28.5562° N, 77.1000° E",
            shortName: "Delhi Airport",
            parentName: "New Delhi",
            grandparentName: "Delhi"
        )

        var body: some View {
            NavigationView {
                AirportSearchView(
                    selectedOrigin: $selectedOrigin,
                    selectedDestination: $selectedDestination
                )
            }
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
