import SwiftUI

struct HotelListView: View {
    @State private var hotels: [HotelLocation] = [] // Updated model type
    @State private var locationQuery: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    // Title
                    Text("Find Hotels in Your Desired Location")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.top)

                    // Location input field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 12)

                        TextField("Enter Location", text: $locationQuery)
                            .padding(10)
                            .foregroundColor(.primary)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(12)
                    .shadow(color: Color.gray.opacity(0.4), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    // Search button
                    Button(action: {
                        handleSearch()
                    }) {
                        Text("Search Hotels")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(locationQuery.isEmpty
                                ? LinearGradient(
                                    gradient: Gradient(colors: [Color.gray]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .disabled(locationQuery.isEmpty)
                    .padding(.horizontal)

                    // Loading indicator
                    if isLoading {
                        ProgressView("Loading...")
                            .padding()
                            .scaleEffect(1.3)
                            .foregroundColor(.blue)
                    }

                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top)
                    }

                    // Hotel list
                    if !isLoading && hotels.isEmpty && errorMessage == nil {
                        Spacer()
                        Text("No hotels available for the entered location.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(hotels) { hotel in
                                    // NavigationLink to SearchHotelsListView
                                    NavigationLink(
                                        destination: SearchHotelsListView(geoId: "\(hotel.geoId)")
                                    ) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(hotel.title)
                                                .font(.headline)
                                                .foregroundColor(.primary)

                                            Text("Geo ID: \(hotel.geoId)")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            Text("Location: \(hotel.secondaryText)")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(color: Color.gray.opacity(0.4), radius: 4, x: 0, y: 2)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.top, 16)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Hotel Recommendations")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func handleSearch() {
        if locationQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Location cannot be empty. Please enter a valid location."
            debugLog("DEBUG: Location query is empty.")
        } else {
            debugLog("DEBUG: Starting search for location: \(locationQuery)")
            fetchHotels(location: locationQuery)
        }
    }

    private func fetchHotels(location: String) {
        guard !location.isEmpty else {
            errorMessage = "Please enter a location to search for hotels."
            debugLog("DEBUG: Empty location entered in fetchHotels.")
            return
            return
        }

        isLoading = true
        errorMessage = nil
        hotels = []

        debugLog("DEBUG: Fetching hotels for location: \(location)")

        HotelAPI.searchHotels(locationQuery: location) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedHotels):
                    if fetchedHotels.isEmpty {
                        errorMessage = "No hotels found for the location: \(location)."
                        debugLog("DEBUG: No hotels found for location: \(location)")
                    } else {
                        hotels = fetchedHotels
                        debugLog("DEBUG: Fetched \(hotels.count) hotels for location: \(location)")
                    }
                case .failure(let error):
                    errorMessage = "Error fetching hotels: \(error.localizedDescription)"
                    debugLog("DEBUG: Error fetching hotels: \(error.localizedDescription)")
                }
            }
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}

struct HotelListView_Previews: PreviewProvider {
    static var previews: some View {
        HotelListView()
    }
}
