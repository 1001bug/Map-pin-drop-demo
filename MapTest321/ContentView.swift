import SwiftUI
import MapKit

struct MapPin: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    
    static func ==(lhs: MapPin, rhs: MapPin) -> Bool {
                    return lhs.id == rhs.id
            && lhs.coordinate.isEqual(to: rhs.coordinate)
            && lhs.title == rhs.title
                }
}

extension CLLocationCoordinate2D {
    func isEqual(to coordinate: CLLocationCoordinate2D) -> Bool {
        return abs(self.latitude - coordinate.latitude) < 0.0001 &&
               abs(self.longitude - coordinate.longitude) < 0.0001
    }
}

// MARK: - Main App Entry Point
struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Map pin drop demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                //Text("Choose an implementation approach:")
                //    .font(.headline)
                 //   .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    NavigationLink(destination: LongPressGestureBasedMapView()) {
                        ApproachButton(
                            title: "Approach 1: Straitforward LongPressGesture",
                            subtitle: "Works on iOS17 and up. Use LongPressGesture with hack. Require finger release",
                            icon: "hand.tap.fill",
                            color: .orange
                        )
                    }
                    
                    NavigationLink(destination: TimedDragGestureBasedMapView()) {
                        ApproachButton(
                            title: "Approach 2: Timer-Based DragGesture (iOS 18+)",
                            subtitle: "DragGesture + Timer, pins add by timeout, does not require to releas the finger. Does not work on iOS17. No pan, no zoom",
                            icon: "timer",
                            color: .blue
                        )
                    }
                    
                    NavigationLink(destination: UIKitWrappedMapView()) {
                        ApproachButton(
                            title: "Approach 3: UIViewRepresentable",
                            subtitle: "MKMapView and Native UILongPressGestureRecognizer. Works everywhere. BEST implementation",
                            icon: "hand.tap.fill",
                            color: .green
                        )
                    }
                    
                    
                    
                    //AlternativeContentView
                }
                
                Spacer()
                Text("Version 0.1").font(.footnote)
            }
            .padding()
            .navigationTitle("Demo Selector")
            .navigationBarHidden(true)
        }
    }
}

struct ApproachButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}



// MARK: - Approach 1: straitforward LongPressGesture Implementation
struct LongPressGestureBasedMapView: View {
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652), // Philadelphia
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var cameraPositionOld: MapCameraPosition?
    @State private var pins: [MapPin] = []
    @State private var selectedPin: MapPin?
    @State private var selectedPinList: MapPin?
    @State private var newMapPin: MapPin?
    @State private var showPinsSheet: Bool = false
    
    var body: some View {
        ZStack (alignment: .topTrailing){
            MapReader { mapProxy in
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]){
                    ForEach(pins) { pin in
                        Annotation(pin.title, coordinate: pin.coordinate) {
                                Image(systemName: "mappin.circle.fill")
                                .foregroundColor(selectedPin?.id == pin.id || selectedPinList?.id == pin.id ? .blue : .red)
                                    .font(.title)
                                    .onTapGesture {
                                        selectedPin = pin
                                        //showingSheet = true
                                        animateMapToShowPin(pin)
                                    }
                            }
                    }
                }
                .onMapCameraChange { context in
                    cameraPosition = MapCameraPosition.region(context.region)
                    }
                //brings problems with matching screen coord to map coord
                //.ignoresSafeArea()
                
                //THIS IS HACK - allow to pan and zoom (Nobody knows why it works)
                .gesture(DragGesture())
               
                //then real gesture
                .gesture(
                    LongPressGesture(minimumDuration: 0.4, maximumDistance: 0.2)
                        .sequenced(before: SpatialTapGesture(coordinateSpace: .local))
                        .onEnded { value in
                            print("VALUE", value)
                            switch value {
                            case let .second(_, tapValue):
                                guard let point = tapValue?.location else {
                                    print("Unable to retreive tap location from gesture data.")
                                    return
                                }
                                print("POINTS: ", point)
                                guard let mapCoordinate = mapProxy.convert(point, from: .local) else {
                                    print("Unable to convert local point to coordinate on map.")
                                    return
                                }
                                
                                let newPin = MapPin(
                                    coordinate: mapCoordinate,
                                    title: "Pin at \(String(format: "%.4f", mapCoordinate.latitude)), \(String(format: "%.4f", mapCoordinate.longitude))"
                                )
                                
                                print("PIN:", newPin)
                                pins.append(newPin)
                                let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                                    impactMed.impactOccurred()
                                
                                animateMapToShowPin(newPin, false)
                                
                            default: return
                            }
                        }
                )
            }//mapProxy
            
            // Circle with pins count
                        Button(action: {
                            showPinsSheet = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                Text("\(pins.count)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                        }
                        .disabled(pins.count == 0)
                        .sheet(isPresented: $showPinsSheet, onDismiss: {selectedPinList = nil}) {
                            PinsListSheet(pins: $pins, pinFocus: animateMapToShowPin, selectedPin: $selectedPinList)
                                
                            
                        }
        }
        .navigationTitle("Straitforward LongPressGesture")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPin, onDismiss: sheetDismiss) { pin in
            PinDetailSheet(pin: pin) {
                removePin(pin)
            }
        }
    }
    
    private func sheetDismiss(){
        if let old = cameraPositionOld {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = old
            }
            cameraPositionOld = nil
        }
    }
    private func animateMapToShowPin(_ pin: MapPin, _ offset: Bool = true) {
        // Store the original region
       // originalRegion = region
        guard let reg = cameraPosition.region else {
            print("guard fails")
            dump(cameraPosition)
            return
        }
        dump(cameraPosition.region, name: "region OLD")
        
        // Calculate new region to show pin in upper portion of visible area
        let latitudeOffset = reg.span.latitudeDelta * (offset ? 0.25 : 0) //0.25
        
        let newCenter = CLLocationCoordinate2D(
            latitude: pin.coordinate.latitude - latitudeOffset,
            longitude: pin.coordinate.longitude
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPositionOld = cameraPosition
            cameraPosition = MapCameraPosition.region(
                    MKCoordinateRegion(
                    center: newCenter,
                    span: reg.span
                    )
                )
            dump(cameraPosition.region, name: "region NEW")
            
        }
    }
    private func removePin(_ pin: MapPin) {
        pins.removeAll { $0.id == pin.id }
        selectedPin = nil
    }
}

// MARK: - Approach 2: Timed DragGesture Implementation (iOS 18+ Only)
struct TimedDragGestureBasedMapView: View {

    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652), // Philadelphia
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var cameraPositionOld: MapCameraPosition?
    
    @State private var pins: [MapPin] = []
    @State private var selectedPin: MapPin?
    @State private var selectedPinList: MapPin?
    @State private var newMapPin: MapPin?
    @State private var showPinsSheet: Bool = false
    @State private var touchTimer: Timer?
    @State private var touchPosition: CGPoint?
    @State private var touchPositionLast: CGPoint?
    @State private var pressLocation: CGPoint = .zero
    
    var body: some View {
        ZStack (alignment: .topTrailing){
            MapReader { mapProxy in
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]){
                    ForEach(pins) { pin in
                        Annotation(pin.title, coordinate: pin.coordinate) {
                                Image(systemName: "mappin.circle.fill")
                                .foregroundColor(selectedPin?.id == pin.id || selectedPinList?.id == pin.id ? .blue : .red)
                                    .font(.title)
                                    .onTapGesture {
                                        selectedPin = pin
                                        //showingSheet = true
                                        animateMapToShowPin(pin)
                                    }
                            }
                    }
                }
                .onMapCameraChange { context in
                    cameraPosition = MapCameraPosition.region(context.region)
                    }
                //brings problems with matching screen coord to map coord
                //.ignoresSafeArea()

                //no forefront gesture HACK - nothing can make this implementattion wark on iOS17 (no pan, no zoom)
                .simultaneousGesture(
                
                    DragGesture(minimumDistance: 0.0)
                    .onChanged { value in
                        
                        if touchPosition == nil {
                            touchPosition = value.startLocation
                        }
                        touchPositionLast = value.location
                        
                        if touchTimer == nil {
                            
                            
                            touchTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                                // Convert touch point to map coordinates and add pin
                                print("LOCTION: ",value)
                                
                                
                                
                                guard let point = touchPosition else {
                                    print("touchPosition not set")
                                    return
                                } //value.startLocation
                                
                                guard let pointLast = touchPositionLast else {
                                    print("touchPositionLast not set")
                                    return
                                }
                                
                                if abs(point.x - pointLast.x) > 5 || abs(point.y - pointLast.y) > 5  {
                                    print("MOVE OCCURED, SKIP", abs(point.x - pointLast.x) ,abs(point.y - pointLast.y) )
                                    return
                                }
                                
                                
                                guard let mapCoordinate = mapProxy.convert(point, from: .local) else {
                                    print("Unable to convert local point to coordinate on map.")
                                    return
                                }
                                
                                let newPin = MapPin(
                                    coordinate: mapCoordinate,
                                    title: "Pin at \(String(format: "%.4f", mapCoordinate.latitude)), \(String(format: "%.4f", mapCoordinate.longitude))"
                                )
                                
                                print("PIN:", newPin)
                                pins.append(newPin)
                                let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                                    impactMed.impactOccurred()
                                
                                animateMapToShowPin(newPin, false)
                            }
                        }
                    }//onChanged
                    .onEnded { _ in
                        // Cancel timer if finger is lifted before duration
                        print("On Drug End")
                        touchTimer?.invalidate()
                        touchTimer = nil
                        touchPosition = nil
                        touchPositionLast = nil

                    }
                 
                )
            }//mapProxy
            
            // Circle with pins count
                        Button(action: {
                            showPinsSheet = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                Text("\(pins.count)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                        }
                        .disabled(pins.count == 0)
                        .sheet(isPresented: $showPinsSheet, onDismiss: {selectedPinList = nil}) {
                            PinsListSheet(pins: $pins, pinFocus: animateMapToShowPin, selectedPin: $selectedPinList)
                                
                            
                        }
            
        }
        .navigationTitle("Timed DragGesture")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPin, onDismiss: sheetDismiss) { pin in
            PinDetailSheet(pin: pin) {
                removePin(pin)
            }
        }
    }
    
    private func sheetDismiss(){
        if let old = cameraPositionOld {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = old
            }
            cameraPositionOld = nil
        }
    }
    private func animateMapToShowPin(_ pin: MapPin, _ offset: Bool = true) {
        // Store the original region
       // originalRegion = region
        guard let reg = cameraPosition.region else {
            print("guard fails")
            dump(cameraPosition)
            return
        }
        dump(cameraPosition.region, name: "region OLD")
        
        // Calculate new region to show pin in upper portion of visible area
        let latitudeOffset = reg.span.latitudeDelta * (offset ? 0.25 : 0) //0.25
        
        let newCenter = CLLocationCoordinate2D(
            latitude: pin.coordinate.latitude - latitudeOffset,
            longitude: pin.coordinate.longitude
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPositionOld = cameraPosition
            cameraPosition = MapCameraPosition.region(
                    MKCoordinateRegion(
                    center: newCenter,
                    span: reg.span
                    )
                )
            dump(cameraPosition.region, name: "region NEW")
            
        }
    }
    private func removePin(_ pin: MapPin) {
        pins.removeAll { $0.id == pin.id }
        selectedPin = nil
    }
}


struct PinDetailSheet: View {
    //self dismiss
    @Environment(\.dismiss) private var dismiss
    let pin: MapPin
    let pinRemove: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Pin Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing, content: {
                            
                            Button{
                                print("DISS")
                                dismiss()
                            } label: {
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 30, height: 30) // You can make this whatever size, but keep UX in mind.
                                        .overlay(
                                            Image(systemName: "xmark")
                                                .font(.system(size: 12, weight: .bold, design: .rounded)) // This should be less than the frame of the circle
                                                .foregroundColor(.secondary)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle()) // This gives it no designs on idle, but can change on input
                                .accessibilityLabel(Text("Close")) // Keep it accessible
                            
                            
                           
                        })
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coordinates:")
                        .font(.headline)
                    Text("Latitude: \(String(format: "%.6f", pin.coordinate.latitude))")
                    Text("Longitude: \(String(format: "%.6f", pin.coordinate.longitude))")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                Button("Remove Pin") {
                    pinRemove()
                }
                .foregroundColor(.red)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Pin Info")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        
    }
}

struct PinsListSheet: View {
    //self dismiss
    @Environment(\.dismiss) private var dismiss
    @Binding var pins: [MapPin]
    let pinFocus: (MapPin,Bool)  -> Void
    @Binding var selectedPin: MapPin?
    
    var body: some View {
        NavigationView {
            
                    
                
                //DATA
                
                List {
                    ForEach($pins) { $pin in
                        //VStack(alignment: .leading) {
                            
                            Text(pin.title)
                            .onTapGesture {
                                pinFocus(pin, true)
                                selectedPin = pin
                            }
                        //}
                        //.padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        pins.remove(atOffsets: indexSet)
                    }
                }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    HStack {
                        Button {
                            print("REMOVEALL")
                            pins.removeAll()
                        } label: {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 30, height: 30) // You can make this whatever size, but keep UX in mind.
                                .overlay(
                                    Image(systemName: "square.stack.3d.up.slash")
                                        .font(.system(size: 12, weight: .bold, design: .rounded)) // This should be less than the frame of the circle
                                        .foregroundColor(.secondary)
                                )
                        }
                        .buttonStyle(PlainButtonStyle()) // This gives it no designs on idle, but can change on input
                        .accessibilityLabel(Text("Close")) // Keep it accessible
                        
                        
                        
                        Button {
                            print("DISS")
                            dismiss()
                        } label: {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 30, height: 30) // You can make this whatever size, but keep UX in mind.
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .bold, design: .rounded)) // This should be less than the frame of the circle
                                        .foregroundColor(.secondary)
                                )
                        }
                        .buttonStyle(PlainButtonStyle()) // This gives it no designs on idle, but can change on input
                        .accessibilityLabel(Text("Close")) // Keep it accessible
                        
                        
                    }
                    //square.stack.3d.up.slash
                   
                })
            }
            .padding()
            .navigationTitle("Pins List")
            .navigationBarTitleDisplayMode(.inline)
            //.navigationBarHidden(true)
        }
        .presentationDetents([.medium])
        
    }
}

// MARK: - Approach 3: UIViewRepresentable Implementation - BEST IMPL
struct UIKitWrappedMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652), // Philadelphia
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var pins: [MapPin] = []
    @State private var selectedPin: MapPin?
    @State private var showingSheet = false
    @State private var selectedPinList: MapPin?
    @State private var showPinsSheet: Bool = false
    
    var body: some View {
        ZStack (alignment: .topTrailing){
            
            MapViewRepresentable(
                pins: $pins,
                selectedPin: $selectedPin,
                region: $region,
                onPinSelected: { pin in
                    animateMapToShowPin(pin)
                },
                onPinAdded: { pin in
                    animateMapToShowPin(pin, false)
                }
                
            )
            .ignoresSafeArea()
            
            // Circle with pins count
                        Button(action: {
                            showPinsSheet = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                Text("\(pins.count)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                        }
                        .disabled(pins.count == 0)
                        .sheet(isPresented: $showPinsSheet, onDismiss: {selectedPinList = nil}) {
                            PinsListSheet(pins: $pins, pinFocus: animateMapToShowPin, selectedPin: $selectedPinList)
                                
                            
                        }
        }
            .navigationTitle("MKMapView UIKit Wrapped Approach")
            .navigationBarTitleDisplayMode(.inline)
            //.onChange(of: selectedPin) { pin in
            //    if let pin {
            //        //showingSheet = true
            //        //animateMapToShowPin(pin)
            //    }
            //}
            .sheet(item: $selectedPin, onDismiss: sheetDismiss) { pin in
                PinDetailSheet(pin: pin) {
                    removePin(pin)
                }
            }
    }
    
    private func sheetDismiss(){
        print("Sheet dismissed")
    }
    private func animateMapToShowPin(_ pin: MapPin, _ offset: Bool = true) {
        // Store the original region
       // originalRegion = region
        
        // Calculate new region to show pin in upper portion of visible area
        let latitudeOffset = region.span.latitudeDelta * (offset ? 0.25 : 0) //0.25
        
        let newCenter = CLLocationCoordinate2D(
            latitude: pin.coordinate.latitude - latitudeOffset,
            longitude: pin.coordinate.longitude
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: newCenter,
                span: region.span
            )
        }
    }
    
    private func removePin(_ pin: MapPin) {
        pins.removeAll { $0.id == pin.id }
        selectedPin = nil
        //showingSheet = false
    }
}


struct MapViewRepresentable: UIViewRepresentable {
    @Binding var pins: [MapPin]
    @Binding var selectedPin: MapPin?
    @Binding var region: MKCoordinateRegion
    let onPinSelected: ((MapPin) -> Void)?
    let onPinAdded: ((MapPin) -> Void)?
    
    init(pins: Binding<[MapPin]>, selectedPin: Binding<MapPin?>, region: Binding<MKCoordinateRegion>, onPinSelected: ((MapPin) -> Void)? = nil, onPinAdded: ((MapPin) -> Void)? = nil) {
            self._pins = pins
            self._selectedPin = selectedPin
            self._region = region
        self.onPinSelected = onPinSelected
        self.onPinAdded = onPinAdded
        }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        
        // Add long press gesture recognizer
        let longPressGesture = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPressGesture.minimumPressDuration = 0.4
        mapView.addGestureRecognizer(longPressGesture)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update annotations
        uiView.removeAnnotations(uiView.annotations)
        
        let annotations = pins.map { pin -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.title = pin.title
            return annotation
        }
        uiView.addAnnotations(annotations)
        
        // Update region if needed
        if !uiView.region.center.isEqual(to: region.center) {
            uiView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            
            let mapView = gesture.view as! MKMapView
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let newPin = MapPin(
                coordinate: coordinate,
                title: "Pin at \(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
            )
            
            DispatchQueue.main.async {
                self.parent.pins.append(newPin)
                let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                    impactMed.impactOccurred()
                self.parent.onPinAdded?(newPin)
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation,
                  let pin = parent.pins.first(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) else {
                return
            }
            
            DispatchQueue.main.async {
                self.parent.selectedPin = pin
                self.parent.onPinSelected?(pin)
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}




#Preview {
    ContentView()
}
