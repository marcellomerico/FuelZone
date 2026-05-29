import SwiftUI

struct IntensityModePicker: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        FuelZoneSegmentedPicker(
            options: [
                (.simple, "session.intensity.simple"),
                (.zoneBased, "session.intensity.zoneBased")
            ],
            selection: Binding(
                get: { viewModel.setup.intensityMode },
                set: { viewModel.selectIntensityMode($0) }
            )
        )
    }
}
