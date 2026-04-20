import { execAsync } from "ags/process"
import Button from "./Button"

export default function HyprkarlMenu() {
    return (
        <Button execPrimary={() => execAsync("hyprkarl-menu").catch(() => {})}>
            <label label="" />
        </Button>
    )
}