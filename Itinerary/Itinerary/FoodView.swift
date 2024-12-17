import SwiftUI

struct RestaurantListView: View {
    @State private var restaurants: [DetailedRestaurant] = []
    @State private var locationQuery: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var selectedRestaurantDetail: API2.DetailedRestaurantData? = nil

    var body: some View {
        NavigationView {
            VStack {
                // Search UI
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Enter Location", text: $locationQuery)
                        .padding()
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal)
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                .padding(.horizontal)

                Button(action: {
                    withAnimation {
                        searchRestaurants(location: locationQuery)
                    }
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Search Restaurants")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(locationQuery.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 4)
                }
                .disabled(locationQuery.isEmpty)
                .padding(.horizontal)

                if isLoading {
                    ProgressView("Loading...")
                        .scaleEffect(1.5)
                        .padding()
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                if !isLoading && restaurants.isEmpty && errorMessage == nil {
                    Text("No restaurants available.")
                        .font(.headline)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(restaurants, id: \.locationId) { restaurant in
                                NavigationLink(
                                    destination: Rest(restaurantID: restaurant.restaurantsId) // Pass restaurantsId (String)
                                ) {
                                    RestaurantCardView(restaurant: restaurant)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal)
                                }
                            }

                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Restaurant Recommendations")
        }
    }

    private func searchRestaurants(location: String) {
        guard !location.isEmpty else {
            errorMessage = "Please enter a location to search for restaurants."
            return
        }

        isLoading = true
        errorMessage = nil
        restaurants = []

        RestaurantAPI.getRestaurants(locationQuery: location) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let detailedRestaurants):
                    if let firstRestaurant = detailedRestaurants.first {
                        self.fetchRestaurantsByLocation(locationId: firstRestaurant.locationId)
                    } else {
                        self.errorMessage = "No results found for the location: \(location)."
                    }
                case .failure(let error):
                    self.errorMessage = "Error finding location: \(error.localizedDescription)"
                }
            }
        }
    }

    private func fetchRestaurantsByLocation(locationId: Int) {
        isLoading = true
        DetailedRestaurantAPI.fetchDetailedRestaurants(locationId: locationId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let fetchedRestaurants):
                    if fetchedRestaurants.isEmpty {
                        self.errorMessage = "No restaurants found for this location."
                    } else {
                        self.restaurants = fetchedRestaurants.map { data in
                            DetailedRestaurant(
                                locationId: data.locationId,
                                restaurantsId: data.restaurantsId, // Correctly map restaurantsId
                                name: data.name,
                                latitude: data.latitude ?? 0,
                                longitude: data.longitude ?? 0,
                                imageUrl: data.thumbnail?.photo?.photoSizeDynamic?.urlTemplate ?? "",
                                averageRating: data.averageRating,
                                userReviewCount: data.userReviewCount,
                                priceTag: data.priceTag,
                                currentOpenStatusText: data.currentOpenStatusText,
                                hasMenu: data.hasMenu,
                                distanceTo: data.distanceTo // Map distanceTo here
                            )
                        }
                    }
                case .failure(let error):
                    self.errorMessage = "Error fetching restaurants: \(error.localizedDescription)"
                }
            }
        }
    }


    private func fetchRestaurantDetails(locationId: Int) {
        isLoading = true
        print("[DEBUG] Fetching restaurant details for locationId: \(locationId)")
        
        DetailedRestaurantAPI.fetchDetailedRestaurants(locationId: locationId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let details):
                    print("[DEBUG] Successfully fetched restaurant details: \(details)")
                    
                    if let firstDetail = details.first {
                        print("[DEBUG] Selected restaurant detail: \(firstDetail)")
                        self.selectedRestaurantDetail = firstDetail
                    } else {
                        self.errorMessage = "No details available for this restaurant."
                        print("[DEBUG] No details found in the response.")
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load details: \(error.localizedDescription)"
                    print("[DEBUG] Error fetching restaurant details: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct RestaurantDetailView: View {
    let restaurantDetail: API2.DetailedRestaurantData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Display restaurant ID
                Text("Restaurant ID: \(restaurantDetail.restaurantsId)")
                    .font(.largeTitle)
                    .bold()
                    .padding()
            }
        }
    }


    private func mapToDetailedRestaurant(from data: API2.DetailedRestaurantData) -> DetailedRestaurant {
        return DetailedRestaurant(
            locationId: data.locationId,
            restaurantsId: data.restaurantsId,
            name: data.name,
            latitude: data.latitude ?? 0,
            longitude: data.longitude ?? 0,
            imageUrl: data.thumbnail?.photo?.photoSizeDynamic?.urlTemplate ?? "",
            averageRating: data.averageRating // Map averageRating
        )
    }
}

// MARK: - Restaurant Card View
// Updated `RestaurantCardView` for DetailedRestaurant
struct RestaurantCardView: View {
    let restaurant: DetailedRestaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name: \(restaurant.name)")
                .font(.headline)

            if let rating = restaurant.averageRating {
                Text("Rating: \(rating, specifier: "%.1f")")
                    .font(.subheadline)
            } else {
                Text("Rating: Not available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let reviews = restaurant.userReviewCount {
                Text("Reviews: \(reviews)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let price = restaurant.priceTag {
                Text("Price: \(price)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let openStatus = restaurant.currentOpenStatusText {
                Text("Status: \(openStatus)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }


            // Distance to Restaurant
            if let distance = restaurant.distanceTo {
                Text(String(format: "Distance: %.2f km", distance))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            let formattedUrl = restaurant.imageUrl
                .replacingOccurrences(of: "{width}", with: "300")
                .replacingOccurrences(of: "{height}", with: "200")

            if let url = URL(string: formattedUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .cornerRadius(12)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 180)
                }
            } else {
                Text("Image unavailable")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8)
        )
    }
}



// MARK: - Simplified Model for UI
struct DetailedRestaurant: Identifiable, Equatable {
    var id = UUID()
    var locationId: Int
    var restaurantsId: String
    var name: String
    var latitude: Double
    var longitude: Double
    var imageUrl: String
    var averageRating: Double? // Existing property
    var userReviewCount: Int? // Existing property
    var priceTag: String? // Existing property
    var currentOpenStatusText: String? // Existing property
    var hasMenu: Bool? // Existing property
    var distanceTo: Double? // Add this line

    static func == (lhs: DetailedRestaurant, rhs: DetailedRestaurant) -> Bool {
        return lhs.id == rhs.id &&
               lhs.locationId == rhs.locationId &&
               lhs.name == rhs.name &&
               lhs.latitude == lhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.imageUrl == rhs.imageUrl
    }
}




// MARK: - Preview
struct RestaurantListView_Previews: PreviewProvider {
    static var previews: some View {
        RestaurantListView()
    }
}
