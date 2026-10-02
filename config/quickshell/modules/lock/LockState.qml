import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Scope {
  id: root

  property string currentText: ""
  property int submittedLength: 0
  property bool passwordFailed: false
  property bool fingerprintFailed: false
  property bool fingerprintReading: false
  property bool fingerprintAccepted: false
  property bool authenticated: false
  property bool fingerprintAllowed: false
  property bool fingerprintEnabled: false
  property var queuedResponse: null
  property bool awaitingPasswordResponse: false
  readonly property bool passwordBusy: password.active && !awaitingPasswordResponse
  readonly property bool responseVisible:
    password.active && awaitingPasswordResponse && password.responseVisible
  readonly property bool fingerprintBusy: fingerprint.active
  readonly property bool fingerprintActive:
    fingerprintAllowed && fingerprintEnabled && !authenticated
  signal unlocked()

  onFingerprintActiveChanged: {
    if (fingerprintActive) startFingerprint()
    else stopFingerprint()
  }

  // Scan only when fingers are enrolled; hk-fingerprint setup is the opt-in.
  Process {
    command: ["hk-fingerprint", "list"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.fingerprintEnabled = text.trim().length > 0
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
    if (!fingerprintActive || fingerprint.active) return
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
  }

  // Retry a mismatch at once; give a failing reader a moment.
  function retryFingerprint(readerError: bool): void {
    fingerprintRetry.interval = readerError ? 2000 : 200
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

  // Quickshell's default service: /etc/pam.d/login.
  PamContext {
    id: password
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
    configDirectory: Quickshell.shellPath("modules/lock/pam")
    config: "fingerprint"

    onPamMessage: root.fingerprintFailed = messageIsError
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
