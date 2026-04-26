import { Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import Button from "../../button/Button"

function formatProfileLabel(profileName: string) {
  return profileName
    .split("-")
    .map((word) => word[0].toUpperCase() + word.slice(1))
    .join(" ")
}

type Props = {
  activeProfile: Accessor<string>
  profiles: Array<AstalPowerProfiles.Profile>
  onSelect: (profileName: string) => void
}

export default function PowerProfileMenu({
  activeProfile,
  profiles,
  onSelect,
}: Props) {
  return (
    <>
      {profiles.map(({ profile }) => (
        <Button
          class={activeProfile((currentProfile) =>
            currentProfile === profile ? "dropdown-row active" : "dropdown-row",
          )}
          hexpand
          halign={Gtk.Align.FILL}
          execPrimary={() => onSelect(profile)}
        >
          <box spacing={8} hexpand halign={Gtk.Align.FILL}>
            <label hexpand xalign={0} label={formatProfileLabel(profile)} />
            <image
              halign={Gtk.Align.END}
              class="dropdown-row-check"
              iconName="object-select-symbolic"
              visible={activeProfile((currentProfile) => currentProfile === profile)}
            />
          </box>
        </Button>
      ))}
    </>
  )
}
