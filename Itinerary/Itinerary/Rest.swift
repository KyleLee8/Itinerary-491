import SwiftUI

struct Rest: View {
    let restaurantID: String

    @State private var restaurantDetails: API3.RestaurantDetailsData?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)

            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading restaurant details...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.red)
                    Text("Oops, something went wrong!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button(action: {
                        fetchRestaurantDetails()
                    }) {
                        Text("Retry")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    .padding(.horizontal)
                }
            } else if let restaurantDetails = restaurantDetails {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Hero Image Section
                        if let mediaItem = restaurantDetails.heroMedia?.media?.first,
                           let url = mediaItem.sizes?.first?.url {
                            let formattedUrl = url
                                .replacingOccurrences(of: "{width}", with: "600")
                                .replacingOccurrences(of: "{height}", with: "400")
                            if let imageUrl = URL(string: formattedUrl) {
                                ZStack(alignment: .bottomLeading) {
                                    AsyncImage(url: imageUrl) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 240)
                                            .cornerRadius(16)
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 240)
                                    }

                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.black.opacity(0.6), .clear]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                    .cornerRadius(16)
                                    .frame(height: 240)

                                    Text(restaurantDetails.overview?.name ?? "Restaurant")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding()
                                }
                            }
                        }

                        // Overview Section
                        SectionHeaderView(icon: "info.circle", title: "Overview")
                        VStack(alignment: .leading, spacing: 8) {
                            if let rating = restaurantDetails.overview?.rating {
                                HStack {
                                    Text("⭐️ Rating:")
                                        .font(.headline)
                                    Text("\(rating, specifier: "%.1f")")
                                        .font(.body)
                                }
                            }

                            if let reviews = restaurantDetails.overview?.numberReviews {
                                HStack {
                                    Text("📝 Reviews:")
                                        .font(.headline)
                                    Text("\(reviews) reviews")
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                        // About Section
                        if let aboutContent = restaurantDetails.about?.content, !aboutContent.isEmpty {
                            SectionHeaderView(icon: "book.fill", title: "About")
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(aboutContent, id: \.title?.text) { item in
                                    if let title = item.title?.text {
                                        Text(title)
                                            .font(.headline)
                                    }
                                    if let list = item.list {
                                        ForEach(list, id: \.text) { listItem in
                                            HStack {
                                                Text("•")
                                                Text(listItem.text ?? "Unknown")
                                                    .font(.body)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }

                        // Open Hours Section
                        if let hoursForDays = restaurantDetails.openHours?.hoursForDays {
                            SectionHeaderView(icon: "clock.fill", title: "Open Hours")
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(hoursForDays, id: \.day?.text) { day in
                                    if let dayName = day.day?.text {
                                        Text(dayName)
                                            .font(.headline)
                                    }
                                    if let intervals = day.localizedIntervals {
                                        ForEach(intervals, id: \.text) { interval in
                                            Text(interval.text ?? "Closed")
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }

                        // Reviews Section
                        if let reviews = restaurantDetails.reviews?.content {
                            SectionHeaderView(icon: "star.fill", title: "Reviews")
                            ForEach(reviews, id: \.htmlTitle?.text) { review in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(review.htmlTitle?.text ?? "Review")
                                        .font(.headline)
                                    Text(review.htmlText?.text ?? "No review text available.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("No details available.")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            fetchRestaurantDetails()
        }
        .navigationTitle("Restaurant Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fetchRestaurantDetails() {
        isLoading = true
        errorMessage = nil

        RestaurantDetailsAPI.fetchRestaurantDetails(restaurantID: restaurantID) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    restaurantDetails = response.data
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Section Header View
struct SectionHeaderView: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding(.bottom, 8)
    }
}
