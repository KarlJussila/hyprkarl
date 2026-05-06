/// <reference path="./@girs/gi.d.ts" />
/// <reference path="./@girs/astal-4.0.d.ts" />
/// <reference path="./@girs/@girs/astalbattery-0.1.d.ts" />
/// <reference path="./@girs/@girs/astalhyprland-0.1.d.ts" />
/// <reference path="./@girs/@girs/astalpowerprofiles-0.1.d.ts" />
/// <reference path="./@girs/@girs/astaltray-0.1.d.ts" />

declare const SRC: string

declare module "inline:*" {
  const content: string
  export default content
}

declare module "*.scss" {
  const content: string
  export default content
}

declare module "*.blp" {
  const content: string
  export default content
}

declare module "*.css" {
  const content: string
  export default content
}
