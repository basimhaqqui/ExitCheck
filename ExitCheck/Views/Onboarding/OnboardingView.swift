import SwiftUI
import SwiftData
import CoreLocation

struct OnboardingView: View {
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            WelcomePage(currentPage: $currentPage)
                .tag(0)

            HowItWorksPage(currentPage: $currentPage)
                .tag(1)

            LocationPermissionPage(currentPage: $currentPage)
                .tag(2)

            SetHomePage(currentPage: $currentPage)
                .tag(3)

            ChooseTemplatePage()
                .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .animation(.easeInOut, value: currentPage)
    }
}

struct WelcomePage: View {
    @Binding var currentPage: Int

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .symbolEffect(.bounce, value: currentPage)

                Text("ExitCheck")
                    .font(.system(size: 42, weight: .bold, design: .rounded))

                Text("Never forget the essentials\nwhen leaving home")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                OnboardingButton(title: "Get Started") {
                    withAnimation {
                        currentPage = 1
                    }
                }

                PageIndicator(currentPage: currentPage, totalPages: 5)
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 30)
    }
}

struct HowItWorksPage: View {
    @Binding var currentPage: Int

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("How It Works")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            VStack(alignment: .leading, spacing: 30) {
                HowItWorksRow(
                    icon: "mappin.circle.fill",
                    color: .red,
                    title: "Set Your Home",
                    description: "Mark your home location on the map"
                )

                HowItWorksRow(
                    icon: "checklist",
                    color: .blue,
                    title: "Create Your List",
                    description: "Add items you need every time you leave"
                )

                HowItWorksRow(
                    icon: "location.fill",
                    color: .green,
                    title: "Auto-Detect Exit",
                    description: "Get a checklist when you leave home"
                )

                HowItWorksRow(
                    icon: "checkmark.circle.fill",
                    color: .orange,
                    title: "Check & Go",
                    description: "Confirm you have everything, then go!"
                )
            }
            .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 16) {
                OnboardingButton(title: "Continue") {
                    withAnimation {
                        currentPage = 2
                    }
                }

                PageIndicator(currentPage: currentPage, totalPages: 5)
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 30)
    }
}

struct HowItWorksRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct LocationPermissionPage: View {
    @Binding var currentPage: Int
    @EnvironmentObject private var locationManager: LocationManager
    @State private var showDeniedAlert = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, isActive: true)

                Text("Location Access")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("ExitCheck needs \"Always\" location access to detect when you leave home, even when the app is closed.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 16) {
                PermissionInfoRow(
                    icon: "lock.shield",
                    text: "Your location stays on your device"
                )

                PermissionInfoRow(
                    icon: "battery.100",
                    text: "Uses minimal battery with geofencing"
                )

                PermissionInfoRow(
                    icon: "hand.raised",
                    text: "Only monitors your home zone"
                )
            }
            .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 16) {
                if locationManager.hasAlwaysAuthorization {
                    OnboardingButton(title: "Continue", color: .green) {
                        withAnimation {
                            currentPage = 3
                        }
                    }
                } else if locationManager.authorizationStatus == .authorizedWhenInUse {
                    VStack(spacing: 12) {
                        Text("Please select \"Always\" in Settings")
                            .font(.subheadline)
                            .foregroundStyle(.orange)

                        OnboardingButton(title: "Open Settings", color: .orange) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                } else if locationManager.authorizationStatus == .denied {
                    VStack(spacing: 12) {
                        Text("Location access denied")
                            .font(.subheadline)
                            .foregroundStyle(.red)

                        OnboardingButton(title: "Open Settings", color: .red) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                } else {
                    OnboardingButton(title: "Continue") {
                        if locationManager.authorizationStatus == .notDetermined {
                            locationManager.requestAlwaysAuthorization()
                        }
                    }
                }

                PageIndicator(currentPage: currentPage, totalPages: 5)
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 30)
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .authorizedAlways {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        currentPage = 3
                    }
                }
            }
        }
    }
}

struct PermissionInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct SetHomePage: View {
    @Binding var currentPage: Int
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var radius: Double = 100
    @State private var isSettingLocation = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                Text("Set Your Home")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("We'll create a zone around your home to detect when you leave")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 20) {
                OnboardingButton(title: "Use Current Location", icon: "location.fill") {
                    useCurrentLocation()
                }

                OnboardingButton(title: "Pick on Map", icon: "map", color: .secondary) {
                    // For simplicity, we'll use current location
                    // A full implementation would show a map picker
                    useCurrentLocation()
                }
            }

            if selectedCoordinate != nil {
                VStack(spacing: 12) {
                    Text("Home location set!")
                        .font(.headline)
                        .foregroundStyle(.green)

                    HStack {
                        Text("Zone radius:")
                        Slider(value: $radius, in: 50...300, step: 25)
                        Text("\(Int(radius))m")
                            .monospacedDigit()
                    }
                    .padding(.horizontal)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            VStack(spacing: 16) {
                if selectedCoordinate != nil {
                    OnboardingButton(title: "Continue", color: .green) {
                        saveHomeLocation()
                        withAnimation {
                            currentPage = 4
                        }
                    }
                }

                PageIndicator(currentPage: currentPage, totalPages: 5)
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 30)
    }

    private func useCurrentLocation() {
        isSettingLocation = true
        locationManager.requestCurrentLocation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let location = locationManager.currentLocation {
                withAnimation {
                    selectedCoordinate = location.coordinate
                }
            }
            isSettingLocation = false
        }
    }

    private func saveHomeLocation() {
        guard let coordinate = selectedCoordinate else { return }

        let homeLocation = HomeLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            radius: radius
        )
        modelContext.insert(homeLocation)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save home location: \(error)")
        }
    }
}

struct ChooseTemplatePage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var homeLocations: [HomeLocation]
    @State private var selectedTemplate: ChecklistTemplate?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Quick Start")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("Choose a template or start from scratch")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 60)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(ChecklistTemplate.allTemplates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTemplate = template
                                HapticManager.selection()
                            }
                        }
                    }

                    TemplateCard(
                        name: "Start Empty",
                        icon: "plus.circle",
                        description: "Build your own list",
                        isSelected: selectedTemplate == nil
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTemplate = nil
                            HapticManager.selection()
                        }
                    }
                }
                .padding(.horizontal)
            }

            VStack(spacing: 16) {
                OnboardingButton(title: "Finish Setup", color: .green) {
                    finishOnboarding()
                }

                PageIndicator(currentPage: 4, totalPages: 5)
            }
            .padding(.bottom, 50)
            .padding(.horizontal, 30)
        }
    }

    private func finishOnboarding() {
        if let template = selectedTemplate {
            let items = template.toChecklistItems()
            for item in items {
                modelContext.insert(item)
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save checklist items: \(error)")
        }

        if let homeLocation = homeLocations.first {
            LocationManager.shared.startMonitoring(for: homeLocation)
        }

        HapticManager.notification(.success)
        appState.hasCompletedOnboarding = true
    }
}

struct TemplateCard: View {
    var template: ChecklistTemplate? = nil
    var name: String = ""
    var icon: String = ""
    var description: String = ""
    let isSelected: Bool
    let action: () -> Void

    var displayName: String { template?.name ?? name }
    var displayIcon: String { template?.icon ?? icon }
    var displayDescription: String { template?.description ?? description }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: displayIcon)
                    .font(.title)
                    .foregroundStyle(isSelected ? .white : .blue)

                Text(displayName)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(displayDescription)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .blue

    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.buttonTap()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(NotificationManager.shared)
}
