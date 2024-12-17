import SwiftUI

struct RentalSearchView: View {
    let geoId: Int
    let locationName: String

    @State private var rentals: [Rental] = []
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSortOrder = "POPULARITY"

    @State private var arrivalDate: Date? = nil
    @State private var departureDate: Date? = nil

    var body: some View {
        VStack {
            // Date Selection
            HStack {
                VStack(alignment: .leading) {
                    Text("Departure Date")
                        .font(.caption)
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { arrivalDate ?? Date() },
                            set: { newValue in
                                arrivalDate = newValue
                                if let departure = departureDate, newValue >= departure {
                                    departureDate = Calendar.current.date(byAdding: .day, value: 1, to: newValue)
                                }
                            }
                        ),
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                }
                .padding()

                VStack(alignment: .leading) {
                    Text("Arrival Date")
                        .font(.caption)
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { departureDate ?? (arrivalDate?.addingTimeInterval(86400) ?? Date().addingTimeInterval(86400)) },
                            set: { newValue in
                                departureDate = newValue
                                if let arrival = arrivalDate, newValue <= arrival {
                                    arrivalDate = Calendar.current.date(byAdding: .day, value: -1, to: newValue)
                                }
                            }
                        ),
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                }
                .padding()
            }

            // Sorting
            HStack {
                Text("Sort by:")
                    .font(.headline)
                Picker("", selection: $selectedSortOrder) {
                    Text("Popularity").tag("POPULARITY")
                    Text("Price Low to High").tag("PRICELOW")
                    Text("Price High to Low").tag("PRICEHIGH")
                    Text("Traveler Rating").tag("TRAVELERRATINGHIGH")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedSortOrder) { _ in
                    currentPage = 1
                    rentals = []
                    fetchRentals()
                }
            }
            .padding()

            // Rentals List
            if isLoading {
                ProgressView("Loading Rentals...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if rentals.isEmpty {
                Text("No rentals found in \(locationName)")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    ForEach(rentals, id: \.rentalId) { rental in
                        HStack(alignment: .top, spacing: 10) {
                            // House Icon
                            Image(systemName: "house.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.blue)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 10) {
                                // Rental Name
                                Text(rental.name)
                                    .font(.headline)

                                // Rate Section
                                if let rateDetails = rental.rate?.details?.first, let amount = rateDetails.rate?.amount {
                                    Text("Price: \(amount, specifier: "%.2f") \(rateDetails.rate?.currency ?? "USD")")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Price information not available")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }

                                // Decorative Divider
                                Divider()
                                    .background(Color.gray)
                                    .padding(.vertical, 5)
                            }
                            .padding(.leading, 5)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 2)
                        )
                        .padding(.vertical, 8)
                    }

                    // Pagination Button
                    if currentPage < totalPages {
                        Button(action: {
                            currentPage += 1
                            fetchRentals()
                        }) {
                            Text("Load More")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue)
                                        .opacity(0.8)
                                )
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchRentals()
        }
        .navigationTitle("Rentals in \(locationName)")
    }

    private func fetchRentals() {
        guard let arrival = arrivalDate, let departure = departureDate else {
            errorMessage = "Please select both arrival and departure dates."
            return
        }

        let today = Date()
        if arrival < today || departure < today {
            errorMessage = "Arrival and departure dates must be in the future."
            return
        }

        guard departure > arrival else {
            errorMessage = "Departure date must be after arrival date."
            return
        }

        isLoading = true
        errorMessage = nil

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let formattedArrival = dateFormatter.string(from: arrival)
        let formattedDeparture = dateFormatter.string(from: departure)

        APIManager.shared.fetchRentals(
            geoId: geoId,
            sortOrder: selectedSortOrder,
            page: currentPage,
            arrival: arrival,
            departure: departure
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    rentals.append(contentsOf: response)
                    totalPages = response.count > 0 ? 1 : 0 // Adjust logic based on API response
                    isLoading = false
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct RentalSearchView_Previews: PreviewProvider {
    static var previews: some View {
        RentalSearchView(geoId: 60763, locationName: "New York")
    }
}
