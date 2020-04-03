# CombinedGregorianSchedule

A concrete `Schedule` type consisting of the composition of two or more  `GregorianCommonTimetable` instances.

## Introduction
`GregorianCommonTimetable` concrete `Schedule` works for creating schedule timetables based on a single calendric unit —months, days of month, weekdays or day's hours— in order to create schedule timetables more complex, the `CombinedGregorianSchedule` comes handy to fill the gap.
This type basically intoduces the `refine` operation concept, which is the narrowing of a schedule timetible's elements via another schedule timetable. 
For example given a `GregorianCommonTimetable` whose kind is `monthlyBased`, combining it via `refine` with another `GregorianCommonTimetable` of kind `dailyBased` will result in a schedule timetable returning only the elements of the latter one —days of month— falling on the elements of the former one —months.

## Usage
Aside for the `Schedule` protocol common operations, this type provides opeations for creating and recombining its instances.

### Initalization via `init(refining: by: )`
The public initializer takes two instances of `GregorianCommonTimetable` and combines them into a new instance of `CombinedGregorianSchedule` by using the `refine` operation. Note that the leftmost parameter should be the schedule timetable to refine and the rightmost the one used for refininition; **that is the `refine` operation takes into account the order of its operands:**
```swift
let months = GregorianCommonTimetable([.january, .february])
let days = GregorianCommonTimetable([.first, .second])

// This will produce a schedule timetable which has as its elements 
//  every 1st and 2nd days of every January and every February:
let timetable = CombinedGregorianSchedule(refining: months, by: days)

// This instead will produce and empty schedule, since a timetable 
//  consisting in days of months cannot be refined by one consisting of
//  months:

let empty = CombinedGregorianSchedule(refining: days, by: months)
```
### Further refining a `CombinedGregorianSchedule` via `refined(by:)` instance method
A `CombinedGregorianSchedule` instance can be further refined via its instance method `refined(by:)`, either by providing as parameter a `GregorianCommonTimetable` instance or another `CombinedGregorianSchedule` instance. 
This operation follows the same guidelines of the `refine` operation:
```swift
let months = GregorianCommonTimetable([.january, .february])
let days = GregorianCommonTimetable([.first, .second])
let weekdays = GregorianCommonTimetable([.monday, .tuesday])
let hours = GregorianCommonTimetable([.am10, .pm10])

let daysOnMonths = CombinedGregorianSchedule(refining: months, by: days)

// This will produce a schedule timetable which has as its elements 
//  every Monday and every Tuesday 1st and 2nd days of every January 
//  and Febraury
let weekdaysOnDaysOfMonths = daysOnMonths.refined(by: weekdays)

// We could further refine it:
let hoursOnWeekdaysOnDaysOnMonths = weekdaysOnDaysOfMonths.refined(by: hours)

// We could have also used another CombinedGregorianSchedule to refine
//  the initial one:
let hoursOnWeekdays = CombinedGregorianSchedule(refining: weekdays, by: hours)
let same = daysOnMonths.refined(by: hoursOnWeekdays)
```
### Complexity notes
Every `refine` operation applied to two schedule timetables adds a layer of complexity on the `Schedule.Generator` of the resulting `Schedule.Generator` in terms of *log(n*m)* where *n* is the number of elements to traverse in the *refined* `Schedule.Generator` and *m* is the number of the *refinitor* `Schedule.Generator` elements to traverse before getting to the element searched.


