import QtQuick

QtObject {
  id: root

  required property var flickable
  property real pixelScale: 1.5
  property real wheelStep: 120
  property real flickThreshold: 120
  property real friction: 0.96
  property real frameInterval: 0.008
  property real sampleWindow: 150
  property real momentumVelocity: 0
  property var gestureSamples: []
  property real previousDelta: 0

  function reset(): void {
    momentumVelocity = 0
    gestureSamples = []
    previousDelta = 0
  }

  function softCap(velocity): real {
    const maximum = flickable.maximumFlickVelocity
    const knee = maximum * 0.6
    const magnitude = Math.abs(velocity)
    if (magnitude <= knee) return velocity

    const headroom = maximum - knee
    const cappedMagnitude = knee + headroom
      * (1 - Math.exp(-(magnitude - knee) / headroom))
    return velocity < 0 ? -cappedMagnitude : cappedMagnitude
  }

  function addSample(delta, timestamp): void {
    if (previousDelta * delta < 0) {
      momentumVelocity = 0
      gestureSamples = []
    }

    const recentSamples = gestureSamples.filter(sample =>
      timestamp - sample.timestamp <= sampleWindow)
    recentSamples.push({ "delta": delta, "timestamp": timestamp })
    gestureSamples = recentSamples
    previousDelta = delta
  }

  function sampledVelocity(timestamp): real {
    const samples = gestureSamples.filter(sample =>
      timestamp - sample.timestamp <= sampleWindow)
    if (samples.length < 2) return 0

    const firstTime = samples[0].timestamp
    const lastTime = samples[samples.length - 1].timestamp
    const timeSpan = Math.max(1, lastTime - firstTime)
    let weightedDelta = 0
    let totalWeight = 0
    for (const sample of samples) {
      const weight = 1 + (sample.timestamp - firstTime) / timeSpan
      weightedDelta += sample.delta * weight
      totalWeight += weight
    }
    return weightedDelta / totalWeight / frameInterval
  }

  function advanceMomentum(frameSeconds): void {
    const minimum = flickable.originY
    const maximum = Math.max(minimum,
      minimum + flickable.contentHeight - flickable.height)
    const next = Math.max(minimum,
      Math.min(maximum, flickable.contentY
        - momentumVelocity * frameSeconds))

    if (next === flickable.contentY) {
      momentumVelocity = 0
      return
    }

    flickable.contentY = next
    const nextVelocity = momentumVelocity * Math.pow(
      friction, frameSeconds / frameInterval)
    momentumVelocity = Math.abs(nextVelocity) < flickThreshold
      ? 0
      : nextVelocity
  }

  property WheelHandler wheel: WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    activeTimeout: 0.1
    target: null

    onWheel: event => {
      const delta = event.pixelDelta.y !== 0
        ? event.pixelDelta.y * root.pixelScale
        : event.angleDelta.y / 120 * root.wheelStep
      if (delta === 0) return

      const minimum = root.flickable.originY
      const maximum = Math.max(minimum,
        minimum + root.flickable.contentHeight - root.flickable.height)
      root.flickable.contentY = Math.max(minimum,
        Math.min(maximum, root.flickable.contentY - delta))
      root.addSample(delta, Date.now())
    }

    onActiveChanged: {
      if (active) {
        root.gestureSamples = []
        root.previousDelta = 0
        return
      }

      const releaseVelocity = root.sampledVelocity(Date.now())
      root.momentumVelocity = root.momentumVelocity * releaseVelocity >= 0
        ? root.softCap(root.momentumVelocity + releaseVelocity)
        : root.softCap(releaseVelocity)
      root.gestureSamples = []
      root.previousDelta = 0
    }
  }

  property FrameAnimation animation: FrameAnimation {
    running: !root.wheel.active
      && Math.abs(root.momentumVelocity) >= root.flickThreshold
    onTriggered: root.advanceMomentum(frameTime)
  }
}
