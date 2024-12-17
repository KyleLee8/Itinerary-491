import SwiftUI

struct VacationLocationSearchView: View {
    @Environment(\.presentationMode) var presentationMode // For dismissing the view

    @State private var searchQuery: String = ""
    @State private var vacationLocations: [VacationLocation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hoveredCard: Int? = nil // For hover effects
    @State private var bagScale: CGFloat = 1.0 // Animation for the travel bag

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.3)]),
                               startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    // Back Button and Header Section
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss() // Dismiss the current view
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                            .foregroundColor(.blue)
                            .padding(.leading, 10)
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                    .zIndex(1)

                    ZStack {
                        Image("travel_background") // Replace with a suitable travel-themed image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .overlay(
                                VStack(spacing: 15) {
                                    Text("Explore Vacation Destinations")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .shadow(radius: 5)

                                    Image(systemName: "bag.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white)
                                        .shadow(radius: 5)
                                        .scaleEffect(bagScale)
                                        .animation(
                                            Animation.easeInOut(duration: 1.5)
                                                .repeatForever(autoreverses: true),
                                            value: bagScale
                                        )
                                        .onAppear {
                                            bagScale = 1.2
                                        }
                                }
                            )
                    }

                    // Search Bar with Animation
                    HStack {
                        TextField("Enter a location...", text: $searchQuery)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)

                        Button(action: {
                            fetchData(for: searchQuery)
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .rotationEffect(isLoading ? .degrees(360) : .degrees(0))
                                    .animation(isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default)
                                Text("Search")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(color: .blue.opacity(0.5), radius: 5, x: 0, y: 3)
                        }
                    }
                    .padding()

                    // Results Section
                    if isLoading {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Searching for vacations...")
                                .foregroundColor(.white)
                        }
                        .padding()
                    } else if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    } else if vacationLocations.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "airplane.slash")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                            Text("No results found")
                                .foregroundColor(.white)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack {
                                ForEach(vacationLocations.indices, id: \.self) { index in
                                    let location = vacationLocations[index]
                                    NavigationLink(destination: RentalSearchView(geoId: location.geoId, locationName: location.localizedName)) {
                                        HStack {
                                            AsyncImage(url: validURL(for: location.thumbnail.photoSizeDynamic.urlTemplate)) { image in
                                                image
                                                    .resizable()
                                                    .frame(width: 100, height: 80)
                                                    .cornerRadius(8)
                                            } placeholder: {
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .frame(width: 100, height: 80)
                                                    .foregroundColor(.gray)
                                                    .background(Color.gray.opacity(0.3))
                                                    .cornerRadius(8)
                                            }

                                            VStack(alignment: .leading, spacing: 5) {
                                                Text(location.localizedName)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Text(location.localizedAdditionalNames)
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Image(systemName: "airplane.departure")
                                                .foregroundColor(.blue)
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white)
                                                .shadow(color: hoveredCard == index ? .blue.opacity(0.4) : .gray.opacity(0.4), radius: hoveredCard == index ? 10 : 5, x: 0, y: 3)
                                        )
                                        .scaleEffect(hoveredCard == index ? 1.02 : 1.0) // Hover Effect Scaling
                                        .onHover { isHovering in
                                            hoveredCard = isHovering ? index : nil
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 5)
                                        .transition(.slide)
                                        .animation(.spring())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Locations")
        }
    }

    private func fetchData(for query: String) {
        guard !query.isEmpty else {
            errorMessage = "Please enter a valid location."
            return
        }

        isLoading = true
        errorMessage = nil
        vacationLocations = []

        APIManager.shared.fetchVacationLocations(query: query) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let locations):
                    vacationLocations = locations
                    isLoading = false
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func validURL(for template: String) -> URL? {
        guard !template.isEmpty,
              let urlString = template
                .replacingOccurrences(of: "{width}", with: "100")
                .replacingOccurrences(of: "{height}", with: "80")
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: urlString) else {
            return nil
        }
        return url
    }
}

struct VacationLocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        VacationLocationSearchView()
    }
}
