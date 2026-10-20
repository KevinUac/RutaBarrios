//
//  ContentView.swift
//  RutaBarrios
//
//  Ejercicio: Mapas y Permisos
//  Tópicos Avanzados de Aplicaciones Móviles
//

// Paso 1: frameworks para mapas (MapKit) y ubicación (CoreLocation)
import SwiftUI
import MapKit
import CoreLocation

// Un barrio tradicional de Campeche, ubicado por su iglesia.
struct Barrio: Identifiable {
    let nombre: String
    let latitud: Double
    let longitud: Double
    var id: String { nombre }
    var coordenada: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitud, longitude: longitud)
    }
}

struct ContentView: View {

    // Lugares predefinidos (coordenadas de las iglesias, tomadas de Google Maps)
    let barrios: [Barrio] = [
        Barrio(nombre: "San Román",     latitud: 19.841611,  longitud: -90.5457774),
        Barrio(nombre: "Guadalupe",     latitud: 19.8490853, longitud: -90.53225),
        Barrio(nombre: "San Francisco", latitud: 19.85283,   longitud: -90.52557),
        Barrio(nombre: "Santa Ana",     latitud: 19.839244,  longitud: -90.5261196),
        Barrio(nombre: "Santa Lucía",   latitud: 19.8475871, longitud: -90.5145629)
    ]

    // Paso 2: centro inicial del mapa (iglesia de San Román)
    static let centroInicial = CLLocationCoordinate2D(latitude: 19.841611, longitude: -90.5457774)

    // Paso 3: zoom (0 = máximo acercamiento; 180/360 = planeta entero)
    static let zoomBarrio = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)

    // Paso 4: región inicial; al ser @State, cada cambio redibuja el mapa
    @State private var region = MKCoordinateRegion(center: ContentView.centroInicial,
                                                   span: ContentView.zoomBarrio)

    // Paso 7: barrio elegido en el Picker
    @State private var seleccion = "San Román"

    // Paso 10: el LocationManager forma parte del estado de la vista
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        ZStack {
            // Paso 5: vista Map ligada a la región, con la ubicación del usuario
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: barrios) { barrio in
                MapAnnotation(coordinate: barrio.coordenada) {
                    MarcadorBarrio(nombre: barrio.nombre,
                                   seleccionado: barrio.nombre == seleccion)
                }
            }
            .ignoresSafeArea()

            VStack {
                encabezado
                Spacer()
                controles
            }
        }
    }

    // Tarjeta superior: título y selector de barrio
    private var encabezado: some View {
        VStack(spacing: 4) {
            Text("Ruta de los Barrios")
                .font(.title2.bold())

            // Paso 7: Picker para cambiar entre los barrios
            Picker("Escoge un barrio", selection: $seleccion) {
                ForEach(barrios) { barrio in
                    Text(barrio.nombre).tag(barrio.nombre)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: seleccion) { nuevo in
                if let barrio = barrios.first(where: { $0.nombre == nuevo }) {
                    irA(barrio)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.top, 8)
    }

    // Botones inferiores
    private var controles: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Paso 6: botones que cambian la vista a otro barrio
                Button { mover(-1) } label: {
                    Label("Anterior", systemImage: "chevron.left")
                }
                Button { mover(1) } label: {
                    Label("Siguiente", systemImage: "chevron.right")
                }
            }
            HStack(spacing: 10) {
                // Extra: ajustar el mapa para que quepan todos los barrios
                Button(action: verTodos) {
                    Label("Ver todos", systemImage: "map")
                }
                // Paso 10: centrar el mapa en la ubicación del usuario
                Button {
                    withAnimation { region = locationManager.region }
                } label: {
                    Label("Mi ubicación", systemImage: "location.fill")
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
        .padding(.bottom, 24)
    }

    // Centra el mapa en un barrio
    private func irA(_ barrio: Barrio) {
        withAnimation {
            region = MKCoordinateRegion(center: barrio.coordenada, span: ContentView.zoomBarrio)
        }
    }

    // Avanza o retrocede en la lista de barrios (de forma circular)
    private func mover(_ paso: Int) {
        let actual = barrios.firstIndex(where: { $0.nombre == seleccion }) ?? 0
        let siguiente = (actual + paso + barrios.count) % barrios.count
        seleccion = barrios[siguiente].nombre
    }

    // Calcula una región que contenga a todos los barrios
    private func verTodos() {
        let latitudes = barrios.map(\.latitud)
        let longitudes = barrios.map(\.longitud)
        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max() else { return }

        let centro = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLon + maxLon) / 2)
        // Margen del 60% para que ningún marcador quede pegado al borde
        let zoom = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.6,
                                    longitudeDelta: (maxLon - minLon) * 1.6)
        withAnimation { region = MKCoordinateRegion(center: centro, span: zoom) }
    }
}

// Marcador con ícono de iglesia y nombre del barrio
struct MarcadorBarrio: View {
    let nombre: String
    let seleccionado: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "building.columns.fill")
                .font(seleccionado ? .title2 : .body)
                .foregroundStyle(.white)
                .padding(seleccionado ? 10 : 7)
                .background(seleccionado ? Color.orange : Color.indigo, in: Circle())
                .shadow(radius: 2)
            Text(nombre)
                .font(.caption.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.thinMaterial, in: Capsule())
        }
    }
}
