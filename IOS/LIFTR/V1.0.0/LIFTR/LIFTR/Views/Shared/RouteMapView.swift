import SwiftUI
import MapKit

/// Read-only map of a recorded route (finished workout). Decodes the stored points once.
struct RouteMapView: View {
    let routeData: Data

    private var coordinates: [CLLocationCoordinate2D] {
        let points: [RoutePoint] = RouteCodec.decode(routeData)
        var list: [CLLocationCoordinate2D] = []
        for point in points {
            list.append(CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon))
        }
        return list
    }

    var body: some View {
        let coords: [CLLocationCoordinate2D] = coordinates
        if coords.count >= 2 {
            Map(initialPosition: .automatic, interactionModes: [.zoom, .pan]) {
                MapPolyline(coordinates: coords)
                    .stroke(.blue, lineWidth: 4)
                Marker("Start", coordinate: coords[0])
                    .tint(.green)
                Marker("Finish", coordinate: coords[coords.count - 1])
                    .tint(.red)
            }
            .frame(height: 240)
            .cornerRadius(8)
            .listRowInsets(EdgeInsets())
        }
    }
}
