import QtQuick
import QtTest
import "../config/quickshell/components"

TestCase {
  id: testCase
  name: "ToggleIndicator"

  QtObject {
    id: testTheme

    property var switchAppearance: ({
      "trackLength": 24,
      "trackHeight": 12,
      "trackRadius": 6,
      "thumbSize": 16,
      "thumbRadius": 8,
      "thumbPadding": 7,
      "borderWidth": 2,
      "markFilled": false,
      "fontFamily": "sans",
      "fontSize": 9,
      "onGlyphOffset": [0, 0],
      "offGlyphOffset": [0, 0],
      "transitionDuration": 0
    })
    property color barSurface: "#101010"
    property color accent: "#ff00ff"
    property color border: "#404040"
    property color foreground: "#f0f0f0"
  }

  Component {
    id: indicatorComponent

    ToggleIndicator {}
  }

  function createIndicator(properties) {
    return indicatorComponent.createObject(
      testCase,
      Object.assign({ "theme": testTheme }, properties ?? {}))
  }

  function test_themeDefaultsReproduceTheShippedSwitch() {
    const indicator = createIndicator({})
    verify(indicator !== null)
    compare(indicator.implicitWidth, 28)
    compare(indicator.implicitHeight, 18)
    compare(indicator.trackLength, 24)
    compare(indicator.trackHeight, 12)
    compare(indicator.thumbSize, 16)
    compare(indicator.indicatorBorderWidth, 2)
    indicator.destroy()
  }

  function test_sparseAppearanceOverridesThemeDefaults() {
    const indicator = createIndicator({
      "appearance": {
        "trackLength": 32,
        "trackHeight": 10,
        "trackRadius": 3,
        "thumbSize": 20,
        "thumbRadius": 5,
        "borderWidth": 4,
        "fontSize": 11,
        "onGlyphOffset": [1, -2]
      }
    })
    verify(indicator !== null)
    compare(indicator.implicitWidth, 42)
    compare(indicator.implicitHeight, 24)
    compare(indicator.trackRadius, 3)
    compare(indicator.thumbRadius, 5)
    compare(indicator.glyphFontSize, 11)
    compare(indicator.activeGlyphOffset, [1, -2])
    compare(indicator.inactiveGlyphOffset, [0, 0])
    indicator.destroy()
  }

  function test_markVariantHasOneStationaryThumbAndNoTrackExtent() {
    const indicator = createIndicator({
      "appearance": { "variant": "mark" }
    })
    verify(indicator !== null)
    compare(indicator.implicitWidth, 18)
    compare(indicator.implicitHeight, 18)
    compare(indicator.thumbX, 1)
    compare(indicator.markFilled, false)
    compare(indicator.thumbFillColor, testTheme.barSurface)
    indicator.active = true
    compare(indicator.thumbX, 1)
    compare(indicator.trackColor, testTheme.accent)
    compare(indicator.borderColor, testTheme.accent)
    compare(indicator.thumbFillColor, testTheme.barSurface)
    indicator.destroy()
  }

  function test_markVariantCanOptIntoAccentFill() {
    const indicator = createIndicator({
      "active": true,
      "appearance": {
        "variant": "mark",
        "markFilled": true
      }
    })
    verify(indicator !== null)
    compare(indicator.markFilled, true)
    compare(indicator.thumbFillColor, testTheme.accent)
    indicator.destroy()
  }
}
