import SwiftUI
import MapKit

// Custom Annotation Model
struct MapAnnotationItem: Identifiable {
    let id = UUID() // Unique identifier for each annotation
    let coordinate: CLLocationCoordinate2D
    let title: String
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel // Access shared login state
    @State private var selectedOrigin: AirportAPI.Airport? = nil
    @State private var selectedDestination: AirportAPI.Airport? = nil
    @State private var isDarkMode: Bool = false
    @State private var isAnimatingBanner: Bool = false
    @State private var showWeatherView = false
    @State private var selectedLocation = "Los Angeles"
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.052235, longitude: -118.243683), // Coordinates for Los Angeles
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var mapAnnotations: [MapAnnotationItem] = []

    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: isDarkMode
                        ? [Color.black, Color.gray.opacity(0.6)]
                        : [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(alignment: .leading, spacing: 16) {
                    // Top Header with Logout and Weather Button
                    HStack {
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    NavigationLink(destination: UserPageView()) {
                        Text("User Profile")  // Simple text button
                            .foregroundColor(.blue)  // Blue text color
                            .padding(10)
                            .background(Capsule().strokeBorder(Color.blue, lineWidth: 1)) // Capsule shape with blue border
                    }
                    .padding(.horizontal)
                    // Welcome Text
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Hi")
                                .font(.largeTitle)
                                .foregroundColor(isDarkMode ? .white : .black)
                            Text("User") // You can customize this based on user data.
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                        Text("Let's find out new things")
                            .font(.subheadline)
                            .fontWeight(.light)
                            .foregroundColor(isDarkMode ? .white : .black)
                    }
                    .padding(.horizontal)

                    // Rest of the content remains unchanged
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(isDarkMode ? .white : Color(UIColor.systemIndigo))
                                .padding()

                            Text("Search Hotels, Restaurants, etc...")
                                .font(.footnote)
                                .foregroundColor(isDarkMode ? .gray : .black)
                                .padding()
                            Spacer()
                            Divider().frame(height: 24)
                            Image(systemName: "arrowtriangle.down.fill")
                                .resizable()
                                .frame(width: 8, height: 8)
                                .padding()
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                        .background(isDarkMode ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                        .cornerRadius(80)
                        .shadow(radius: 1)
                        .padding(.horizontal)
                    }

                    // Interactive Map
                    Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
                        MapAnnotation(coordinate: annotation.coordinate) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title)
                                Text(annotation.title)
                                    .font(.footnote)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .frame(height: 200) // Adjust height as needed
                    .cornerRadius(15)
                    .padding()

                    // Navigation Links
                    HStack(spacing: 20) {
                        navigationIcon(index: 0, imageName: "airplane", label: "Flights", color: .blue) {
                            AirportSearchView(selectedOrigin: $selectedOrigin, selectedDestination: $selectedDestination)
                        }

                        navigationIcon(index: 1, imageName: "bed.double.fill", label: "Hotels", color: .gray) {
                            HotelListView()
                        }

                        navigationIcon(index: 2, imageName: "fork.knife.circle.fill", label: "Foods", color: .orange) {
                            RestaurantListView()
                        }

                        navigationIcon(index: 3, imageName: "calendar.badge.clock", label: "Scheduler", color: .red) {
                            SchedulerView()
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Animated Banner
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: isDarkMode
                                        ? [Color.orange.opacity(0.3), Color.red.opacity(0.3)]
                                        : [Color.orange.opacity(0.2), Color.pink.opacity(0.2)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 150)
                            .shadow(radius: 5)
                            .padding(.horizontal)

                        HStack {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Discover Amazing Deals!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(isDarkMode ? .white : .black)
                                Text("Save big on your next trip. Limited time offers!")
                                    .font(.subheadline)
                                    .foregroundColor(isDarkMode ? .white : .black)
                            }
                            Spacer()
                            Image(systemName: "airplane.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(isDarkMode ? .blue : .blue)
                                .rotationEffect(Angle(degrees: isAnimatingBanner ? 360 : 0))
                                .animation(isAnimatingBanner
                                    ? Animation.linear(duration: 2).repeatForever(autoreverses: false)
                                    : .default, value: isAnimatingBanner)
                                .onAppear {
                                    isAnimatingBanner = true
                                }
                        }
                        .padding()
                    }

                    // Dark Mode Toggle
                    HStack {
                        Spacer()
                        Toggle(isOn: $isDarkMode) {
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(isDarkMode ? .yellow : .orange)
                        }
                        .padding()
                    }
                }
                .padding(.top, 20)
            }
        }
        .onAppear {
            mapAnnotations = [
                MapAnnotationItem(
                    coordinate: CLLocationCoordinate2D(latitude: 34.052235, longitude: -118.243683),
                    title: "Los Angeles"
                )
            ]
        }
    }

    // Navigation Icon Component
    private func navigationIcon<Destination: View>(index: Int, imageName: String, label: String, color: Color, destination: @escaping () -> Destination) -> some View {
        VStack(spacing: 5) {
            NavigationLink(destination: destination()) {
                VStack(spacing: 5) {
                    Image(systemName: imageName)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(color)
                        .shadow(color: color.opacity(0.4), radius: 5, x: 0, y: 3)
                    Text(label)
                        .font(.footnote)
                        .bold()
                        .foregroundColor(isDarkMode ? .white : .primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Weather View
struct WeatherView: View {
    let location: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Weather in \(location)")
                .font(.title)
                .fontWeight(.bold)
            Text("This is where the weather data will be displayed.")
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding()
        .navigationTitle("Weather Info")
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
