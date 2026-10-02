import QtQuick

Text {
  required property var theme
  property string navigationSection: ""

  color: theme.panel.foreground
  opacity: 0.7
  font.family: theme.panel.font
  font.pixelSize: theme.typography.readoutSize
  font.capitalization: Font.AllUppercase
  font.letterSpacing: 0.8
}
