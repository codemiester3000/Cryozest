# Mock Data for UI Testing

## TO ENABLE/DISABLE MOCK DATA

Open `MockDataHelper.swift` and change:

```swift
static let useMockData = true  // Change to false to disable
```

## CURRENT MOCK DATA

- **Heart Rate**: 62 bpm (avg: 65 bpm)
- **Steps**: 8,543 steps
- **Water Intake**: 5 cups
- **Activity**: 42 active minutes
  - Light: 15 min
  - Moderate: 25 min
  - Vigorous: 7 min

## TO REMOVE ALL MOCK DATA

Delete these files:
1. `MockDataHelper.swift`
2. `MOCK_DATA_README.md` (this file)

Then remove the mock data checks from:
- `LargeHeartRateWidget.swift` (lines ~28-46)
- `LargeStepsWidget.swift` (lines ~22-25)
- `WaterIntakeCard.swift` (lines ~245-249)
- `ExertionView.swift` (lines ~22-36 and ~271-285)
