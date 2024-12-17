import SwiftUI

struct SchedulerView: View {
    @State private var selectedDate: Date? = nil
    @State private var eventsByDate: [String: [Event]] = [:]  // Store events by date
    @State private var isAddingEvent = false
    @State private var editingEvent: Event? = nil
    @State private var showError = false
    @State private var showDeleteConfirmation = false
    @State private var eventToDelete: Event? = nil
    @Environment(\.presentationMode) var presentationMode // For returning to the homepage

    var body: some View {
        NavigationView {
            VStack {
                if selectedDate == nil {
                    CalendarView(selectedDate: $selectedDate)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Back") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                } else if isAddingEvent || editingEvent != nil {
                    EventInputView(
                        isAddingEvent: $isAddingEvent,
                        editingEvent: $editingEvent,
                        events: $eventsByDate,
                        showError: $showError,
                        selectedDate: selectedDate
                    )
                } else {
                    ScheduleView(
                        events: eventsByDate[selectedDateString()],
                        isAddingEvent: $isAddingEvent,
                        editingEvent: $editingEvent,
                        showDeleteConfirmation: $showDeleteConfirmation,
                        eventToDelete: $eventToDelete,
                        selectedDate: selectedDate
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Back") {
                                selectedDate = nil
                            }
                        }
                    }
                }
            }
            .alert("Invalid Time", isPresented: $showError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text("Ensure start time is before end time and both are within the same day.")
            })
            .alert("Delete Event", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let event = eventToDelete {
                        deleteEvent(event)
                    }
                }
            }
        }
    }

    private func selectedDateString() -> String {
        guard let date = selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func deleteEvent(_ event: Event) {
        guard let selectedDate = selectedDate else { return }
        var eventsForDate = eventsByDate[selectedDateString()] ?? []
        eventsForDate.removeAll { $0.id == event.id }
        eventsByDate[selectedDateString()] = eventsForDate
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date?

    var body: some View {
        VStack {
            Text("Choose a Date")
                .font(.title2)
                .bold()
            DatePicker("Select Date", selection: Binding(get: {
                selectedDate ?? Date()
            }, set: { date in
                selectedDate = date
            }), displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()
        }
    }
}

struct ScheduleView: View {
    var events: [Event]?
    @Binding var isAddingEvent: Bool
    @Binding var editingEvent: Event?
    @Binding var showDeleteConfirmation: Bool
    @Binding var eventToDelete: Event?
    var selectedDate: Date?

    var body: some View {
        VStack {
            HStack {
                Text("Your Schedule")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Button(action: {
                    isAddingEvent = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                }
            }
            .padding()

            if let events = events, !events.isEmpty {
                List {
                    ForEach(events.sorted(by: { $0.startTime < $1.startTime })) { event in
                        EventRow(event: event)
                            .onTapGesture {
                                editingEvent = event
                            }
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    eventToDelete = event
                                    showDeleteConfirmation = true
                                }
                            }
                    }
                }
                .listStyle(.plain)
            } else {
                Text("No events scheduled. Press + to add one.")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}

struct EventInputView: View {
    @Binding var isAddingEvent: Bool
    @Binding var editingEvent: Event?
    @Binding var events: [String: [Event]]
    @Binding var showError: Bool
    var selectedDate: Date?

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()

    var body: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    resetInputs()
                }
                Spacer()
                Text(editingEvent == nil ? "Add Event" : "Edit Event")
                    .font(.headline)
                Spacer()
                Button("Save") {
                    if startTime < endTime {
                        if let editingEvent = editingEvent {
                            updateEvent(editingEvent)
                        } else {
                            addNewEvent()
                        }
                        resetInputs()
                    } else {
                        showError = true
                    }
                }
            }
            .padding()

            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }

                Section(header: Text("Timing")) {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
        }
        .onAppear {
            if let editingEvent = editingEvent {
                title = editingEvent.title
                description = editingEvent.description
                startTime = editingEvent.startTime
                endTime = editingEvent.endTime
            }
        }
    }

    private func addNewEvent() {
        let newEvent = Event(
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime
        )
        
        guard let selectedDate = selectedDate else { return }
        let dateString = selectedDateString(from: selectedDate)
        
        var eventsForDate = events[dateString] ?? []
        eventsForDate.append(newEvent)
        events[dateString] = eventsForDate
    }

    private func updateEvent(_ event: Event) {
        guard let selectedDate = selectedDate else { return }
        let dateString = selectedDateString(from: selectedDate)

        if let index = events[dateString]?.firstIndex(where: { $0.id == event.id }) {
            events[dateString]?[index] = Event(
                id: event.id,
                title: title,
                description: description,
                startTime: startTime,
                endTime: endTime
            )
        }
    }

    private func resetInputs() {
        isAddingEvent = false
        editingEvent = nil
        title = ""
        description = ""
        startTime = Date()
        endTime = Date()
    }

    private func selectedDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct EventRow: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(timeString(from: event.startTime)) - \(timeString(from: event.endTime))")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(event.title)
                    .font(.headline)
            }
            Text(event.description)
                .font(.subheadline)
        }
        .padding()
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct Event: Identifiable {
    let id: UUID
    var title: String
    var description: String
    var startTime: Date
    var endTime: Date

    init(id: UUID = UUID(), title: String, description: String, startTime: Date, endTime: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
    }
}

struct SchedulerView_Previews: PreviewProvider {
    static var previews: some View {
        SchedulerView()
    }
}

