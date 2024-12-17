import SwiftUI

struct SearchHotelsListView: View {
    let geoId: String
    @State private var hotels: [HotelData] = []
    @State private var checkIn: String = dateToString(Date())
    @State private var checkOut: String = dateToString(Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
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
                    Text("Hotels for Geo ID: \(geoId)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.top)

                    // Check-in and Check-out fields
                    DatePicker("Check-In", selection: Binding(get: {
                        SearchHotelsListView.dateFromString(checkIn) ?? Date()
                    }, set: { newDate in
                        checkIn = SearchHotelsListView.dateToString(newDate)
                    }), displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal)
                    .font(.system(size: 18, weight: .medium, design: .rounded))

                    DatePicker("Check-Out", selection: Binding(get: {
                        SearchHotelsListView.dateFromString(checkOut) ?? Date()
                    }, set: { newDate in
                        checkOut = SearchHotelsListView.dateToString(newDate)
                    }), displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal)
                    .font(.system(size: 18, weight: .medium, design: .rounded))

                    // Search button
                    Button(action: {
                        fetchHotels(geoId: geoId, checkIn: checkIn, checkOut: checkOut)
                    }) {
                        Text("Search Hotels")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(checkIn.isEmpty || checkOut.isEmpty
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
                    .disabled(checkIn.isEmpty || checkOut.isEmpty)
                    .padding(.horizontal)

                    // Loading indicator
                    if isLoading {
                        ProgressView("Loading...")
                            .padding()
                            .scaleEffect(1.3)
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }

                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top)
                    }

                    // Hotel list
                    if !isLoading && hotels.isEmpty && errorMessage == nil {
                        Spacer()
                        Text("No hotels found for Geo ID: \(geoId).")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(hotels) { hotel in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(hotel.title ?? "No Title Available")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)

                                        Text("Price: \(hotel.priceForDisplay ?? "N/A")")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary)

                                        if let bubbleRating = hotel.bubbleRating, let rating = bubbleRating.rating {
                                            Text("Rating: \(String(format: "%.1f", rating)) (\(bubbleRating.count ?? "0") reviews)")
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Rating: N/A")
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }

                                        Text(hotel.secondaryInfo ?? "No additional information available")
                                            .font(.system(size: 14, weight: .regular, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.gray.opacity(0.4), radius: 4, x: 0, y: 2)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 16)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Hotel Search")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            fetchHotels(geoId: geoId, checkIn: checkIn, checkOut: checkOut)
        }
    }

    private func fetchHotels(geoId: String, checkIn: String, checkOut: String) {
        isLoading = true
        errorMessage = nil
        hotels = []

        SearchHotelsAPI.searchHotels(geoId: geoId, checkIn: checkIn, checkOut: checkOut) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedHotels):
                    hotels = fetchedHotels
                case .failure(let error):
                    errorMessage = "Error fetching hotels: \(error.localizedDescription)"
                    debugLog("DEBUG: Error fetching hotels: \(error.localizedDescription)")
                }
            }
        }
    }

    private static func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}

struct SearchHotelsListView_Previews: PreviewProvider {
    static var previews: some View {
        SearchHotelsListView(geoId: "12345")
    }
}
