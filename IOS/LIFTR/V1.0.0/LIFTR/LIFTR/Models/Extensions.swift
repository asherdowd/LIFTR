import Foundation

extension Double {
    func toLbs() -> Double {
        return self * 2.20462
    }
    
    func toKg() -> Double {
        return self / 2.20462
    }
    
    func formatted(useMetric: Bool) -> String {
        let value = useMetric ? self.toKg() : self
        let unit = useMetric ? "kg" : "lbs"
        return String(format: "%.1f %@", value, unit)
    }
    
    func convertedValue(useMetric: Bool) -> Double {
        return useMetric ? self.toKg() : self
    }
    
    /// Rounds weight to nearest 5 lbs (or 2.5 kg for metric)
    func roundedToNearestFive(useMetric: Bool = false) -> Double {
        let increment: Double = useMetric ? 2.5 : 5.0
        return (self / increment).rounded() * increment
    }
    
    /// Rounds weight to nearest specified increment
    func roundedToNearest(_ increment: Double) -> Double {
        return (self / increment).rounded() * increment
    }
}
