# Map pin drop demo
## SwiftUI MapKit and UIKit Wrapped Map

Drop pin with long press. Three implementation to compare. 

## Approach 1: Straitforward LongPressGesture
- Works on iOS17 and up
- Uses LongPressGesture with hack
- Require finger release

## Approach 2: Timer-Based DragGesture (iOS 18+)
- DragGesture + Timer
- pin adds by timeout (does not require finger release)
- Does not work on iOS17. No pan, no zoom!

## Approach 3: UIViewRepresentable
- MKMapView and Native UILongPressGestureRecognizer
- Works everywhere.
- BEST implementation
- Require extra code  


## Screensots


<div style="display: flex; flex-wrap: wrap; gap: 15px; justify-content: center;">
  <img src="images/View1.png" alt="Main interface" style="width: 23%; min-width: 100px; max-width: 1500px;" />
  <img src="images/View2.png" alt="Settings page" style="width: 23%; min-width: 100px; max-width: 1500px;" />
  <img src="images/View3.png" alt="Feature demo" style="width: 23%; min-width: 100px; max-width: 1500px;" />
  <img src="images/View4.png" alt="Mobile view" style="width: 23%; min-width: 100px; max-width: 1500px;" />
</div>

## Screensots
![Main Screen](images/View1.png)

![Pins on map](images/View2.png)

![Pin info page](images/View3.png)

![All pins list](images/View4.png)