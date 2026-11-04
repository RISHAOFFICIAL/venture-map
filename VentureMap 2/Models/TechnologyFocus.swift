/// Describes the kind of outreach an organization focuses on.
///
/// Note: nothing in the app currently constructs a `TechnologyFocus` value —
/// it's here as a leftover/placeholder model. It's a good type to experiment
/// on while learning, since changing or deleting it can't break any existing
/// screen.
enum TechnologyFocus: CaseIterable, Identifiable {
    case digitalSkills
    case softwareCareers
    case stemEducation
    case entrepreneurship

    var id: Self { self }

    var title: String {
        switch self {
        case .digitalSkills: "Digital skills"
        case .softwareCareers: "Software careers"
        case .stemEducation: "STEM education"
        case .entrepreneurship: "Tech entrepreneurship"
        }
    }
}
