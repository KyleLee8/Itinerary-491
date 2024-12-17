# Itinerary-491

---

# **Itinerary**  

### **Overview**  
The **Itinerary** is a Swift-based iOS application designed to help users conveniently explore and plan their travels. From searching for flights, hotels, and restaurants to managing their itineraries and schedules, this app provides an all-in-one solution with an intuitive and user-friendly interface.

---

### **Features**  
1. **User Authentication**  
   - Users are greeted with a **LoginView** upon launching the app.  
   - Existing users can input their credentials to log in.  
   - New users can navigate to the **SignUpView** to create an account.

2. **Home Screen (ContentView)**  
   - After successful login, users are redirected to the **ContentView**, which serves as the main dashboard.  
   - The home screen includes:
     - **User Profile**: Leads to user can access their profile  
     - **Quick Navigation Icons**:  
        - **Flights**: Leads to the **AirportSearchView** for searching flights.  
        - **Hotels**: Opens the **HotelListView** to explore hotel options.  
        - **Foods**: Navigates to the **FoodView** for restaurant recommendations.  
        - **Scheduler**: Opens the **SchedulerView** to manage events and travel schedules.

3. **Flight Search**  
   - Users can search for flights by selecting departure and arrival airports and other filters.  
   - Real-time flight options are displayed with essential details such as flight times, carriers, and pricing.

4. **Hotel Search**  
   - Users can search for hotels based on their preferred location.  
   - Hotel options display details such as names, locations, and pricing.

5. **Food Recommendations**  
   - Users can explore restaurant recommendations for their desired location.  
   - Details include ratings, reviews, and open status for better decision-making.

6. **Scheduler and Itinerary Management**  
   - Users can manage their travel events and schedules in the **SchedulerView**.  
   - Events can be created, edited, and deleted with customizable titles, descriptions, and time slots.

---

### **Navigation Flow**  
1. **Launch App** → **LoginView** →  
   - Existing users log in.  
   - New users sign up via **SignUpView**.  
2. **ContentView** →  
   - **Flights**: Navigates to **AirportSearchView**.  
   - **Hotels**: Navigates to **HotelListView**.  
   - **Foods**: Navigates to **FoodView**.  
   - **Scheduler**: Navigates to **SchedulerView**.  

Each navigation option provides specialized functionality and seamless integration with the backend APIs.

---

### **Technology Stack**  
- **SwiftUI**: Provides a modern, declarative UI design for all views.  
- **Combine/State Management**: To manage user input and UI updates efficiently.  
- **Networking**:  
   - APIs: Integration with external APIs (e.g., RapidAPI) for flights, hotels, and restaurants.  
   - URLSession: Handles network requests for fetching and displaying real-time data.  
- **User Authentication**: Handles login/signup functionality with user data validation.  
- **Core Data**: Stores user and itinerary data for persistence.  

---

### **Code Structure**  
- **Views**:  
   - `LoginView`: User login screen.  
   - `SignUpView`: User registration screen.  
   - `ContentView`: Main dashboard after login.  
   - `AirportSearchView`, `FoodView`, `HotelListView`: Specialized views for flights, food, and hotel searches.  
   - `SchedulerView`: Event and itinerary management view.  

- **APIs**:  
   - `FlightSearchAPI`: Fetches flight data.  
   - `HotelAPI` and `SearchHotelsAPI`: Fetches hotel options.  
   - `FoodAPI` and `RestaurantDetailAPI`: Fetches restaurant recommendations.  

- **Models**:  
   - Flight, Hotel, and Restaurant models for structured API data.  

- **Utilities**:  
   - Date handling, error handling, and debug logging utilities.  

---

### **Installation**  
1. Clone the repository.  
   ```
   git clone https://github.com/KyleLee8/Itinerary-491.git
   cd Itinerary-491
   ```
2. Open the project in Xcode.  
3. Run the app on a simulator or connected device.  

---

### **Future Improvements**  
In future updates regarding this application, the first planned set of updates will include features that weren’t fully implemented before launch. This mainly refers to functionalities that weren’t high-priority requirements during development and were pushed beyond the expected release date.

Currently, this includes:

Polishing the main user interface for a more refined user experience.
Adding functionality to view other users’ created schedules, enabling better collaboration and sharing capabilities.
Additionally, future updates will focus on app maintenance to ensure it continues functioning properly well after the launch.

Some additional features being considered include:

The ability to add events directly from the flight, hotel, and restaurant pages to streamline event creation, allowing users to avoid going back and forth between pages and the schedule creation view.

---

