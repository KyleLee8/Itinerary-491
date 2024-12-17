import SwiftUI

struct HierarchicalAirportSearchView: View {
    @State private var airports: [AirportAPI.Airport] = []
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @Binding var selectedOrigin: AirportAPI.Airport?
    @Binding var selectedDestination: AirportAPI.Airport?

    var body: some View {
        NavigationView {
            VStack {
                searchField()
                searchButton()
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    errorText()
                } else if airports.isEmpty {
                    noResultsText()
                } else {
                    airportList()
                }
            }
            .navigationTitle("Search Airports")
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func searchField() -> some View {
        TextField("Search for Airports", text: $searchQuery)
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
    }

    @ViewBuilder
    private func searchButton() -> some View {
        Button(action: {
            searchAirports()
        }) {
            Text("Search Airports")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(searchQuery.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
        }
        .disabled(searchQuery.isEmpty)
    }

    @ViewBuilder
    private func errorText() -> some View {
        Text(errorMessage ?? "An error occurred")
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .padding()
    }

    @ViewBuilder
    private func noResultsText() -> some View {
        Text("No airports found for the entered query.")
            .font(.headline)
            .padding()
    }

    @ViewBuilder
    private func airportList() -> some View {
        List(airports) { airport in
            VStack(alignment: .leading) {
                Text(airport.name)
                    .font(.headline)
                Text("Code: \(airport.airportCode)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Short Name: \(airport.shortName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Parent: \(airport.parentName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Grandparent: \(airport.grandparentName)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Text("Coordinates: \(airport.coordinates)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
            .onTapGesture {
                handleAirportSelection(airport)
            }
        }
    }

    // MARK: - Helper Methods

    private func handleAirportSelection(_ airport: AirportAPI.Airport) {
        if selectedOrigin == nil {
            selectedOrigin = airport
        } else if selectedDestination == nil {
            selectedDestination = airport
        }
        searchQuery = ""
        airports = []
        errorMessage = nil
    }

    private func searchAirports() {
        isLoading = true
        errorMessage = nil
        airports = []

        print("Search query: \(searchQuery)")

        AirportAPI.searchAirports(query: searchQuery) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedAirports):
                    if fetchedAirports.isEmpty {
                        print("No airports found.")
                        errorMessage = "No airports found for the query: \(searchQuery)."
                    } else {
                        print("Fetched airports:")
                        for airport in fetchedAirports {
                            print(" - \(airport.name) (\(airport.airportCode))")
                        }
                        airports = fetchedAirports
                    }
                case .failure(let error):
                    print("Error fetching airports: \(error.localizedDescription)")
                    errorMessage = "Error fetching airports: \(error.localizedDescription)"
                }
            }
        }
    }
}
