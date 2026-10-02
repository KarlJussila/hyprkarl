import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import "../../config"

Scope {
  id: root

  required property var settings
  property string currentText: ""
  property int submittedLength: 0
  property bool passwordFailed: false
  property bool fingerprintFailed: false
  property bool fingerprintReading: false
  property bool fingerprintAccepted: false
  property bool authenticated: false
  property bool fingerprintAllowed: false
  property int fingerprintErrorRetryDelay: 1000
  property var queuedResponse: null
  property bool awaitingPasswordResponse: false
  readonly property bool passwordBusy: password.active && !awaitingPasswordResponse
  readonly property bool responseVisible:
    password.active && awaitingPasswordResponse && password.responseVisible
  readonly property bool fingerprintBusy: fingerprint.active
  signal unlocked()

  onFingerprintAllowedChanged: {
    if (fingerprintAllowed) startFingerprint()
    else stopFingerprint()
  }
  property bool fingerprintAvailable: false
  readonly property bool fingerprintEnabled:
    settings.fingerprintEnabled ?? fingerprintAvailable
  onFingerprintEnabledChanged: {
    if (fingerprintEnabled) startFingerprint()
    else stopFingerprint()
  }

  Process {
    command: ["hk-fingerprint", "list"]
    running: root.settings.fingerprintEnabled === null
    stdout: StdioCollector {
      onStreamFinished: root.fingerprintAvailable = text.trim().length > 0
    }
  }

  function submit(): void {
    if (passwordBusy || currentText.length === 0) return
    passwordFailed = false
    submittedLength = currentText.length
    if (awaitingPasswordResponse) {
      awaitingPasswordResponse = false
      password.respond(currentText)
    } else {
      queuedResponse = currentText
      if (!password.start()) {
        queuedResponse = null
        submittedLength = 0
        passwordFailed = true
      }
    }
    currentText = ""
  }

  function startFingerprint(): void {
    if (!fingerprintAllowed || !fingerprintEnabled
        || fingerprint.active || authenticated) return
    fingerprintFailed = false
    if (!fingerprint.start()) {
      fingerprintFailed = true
      retryFingerprint(true)
    }
  }

  function stopFingerprint(): void {
    fingerprintRetry.stop()
    fingerprint.abort()
    fingerprintReading = false
    fingerprintFailed = false
    fingerprintErrorRetryDelay = 1000
  }

  function retryFingerprint(readerError: bool): void {
    fingerprintRetry.interval = readerError
      ? fingerprintErrorRetryDelay : settings.fingerprintRetryDelay
    if (readerError)
      fingerprintErrorRetryDelay = Math.min(fingerprintErrorRetryDelay * 2, 10000)
    fingerprintRetry.restart()
  }

  function clearAttempt(): void {
    password.abort()
    awaitingPasswordResponse = false
    queuedResponse = null
    currentText = ""
    submittedLength = 0
    passwordFailed = false
  }

  function acceptAuthentication(): void {
    if (authenticated) return
    submittedLength = currentText.length || submittedLength
    authenticated = true
    fingerprintRetry.stop()
    password.abort()
    fingerprint.abort()
    awaitingPasswordResponse = false
    queuedResponse = null
    currentText = ""
    unlocked()
  }

  PamContext {
    id: password
    configDirectory: Paths.userPath("pam")
    config: "password"

    onPamMessage: {
      root.passwordFailed = messageIsError
      if (responseRequired && !responseVisible && root.queuedResponse !== null) {
        const response = root.queuedResponse
        root.queuedResponse = null
        root.awaitingPasswordResponse = false
        respond(response)
      } else {
        root.awaitingPasswordResponse = responseRequired
        if (responseRequired) root.submittedLength = 0
      }
    }
    onCompleted: result => {
      root.queuedResponse = null
      root.awaitingPasswordResponse = false
      if (result === PamResult.Success) {
        root.acceptAuthentication()
      } else {
        root.submittedLength = 0
        root.passwordFailed = true
      }
    }
    onError: error => console.error(`Lock password PAM: ${PamError.toString(error)}`)
  }

  PamContext {
    id: fingerprint
    configDirectory: Paths.userPath("pam")
    config: "fingerprint"

    onPamMessage: {
      root.fingerprintFailed = messageIsError
      if (!messageIsError) root.fingerprintErrorRetryDelay = 1000
    }
    onCompleted: result => {
      if (result === PamResult.Success) {
        root.fingerprintAccepted = true
        root.acceptAuthentication()
      } else {
        root.fingerprintFailed = true
        root.retryFingerprint(result === PamResult.Error)
      }
    }
    onError: error => console.error(`Lock fingerprint PAM: ${PamError.toString(error)}`)
  }

  Timer {
    id: fingerprintRetry
    onTriggered: root.startFingerprint()
  }

  // PAM owns verification. This only observes the reader's presentation state.
  Process {
    command: ["gdbus", "monitor", "--system", "--dest", "net.reactivated.Fprint"]
    running: root.fingerprintBusy
    onRunningChanged: if (!running) root.fingerprintReading = false
    stdout: SplitParser {
      onRead: line => {
        const change = line.match(/'finger-present': <(true|false)>/)
        if (change) root.fingerprintReading = change[1] === "true"
      }
    }
  }
}
