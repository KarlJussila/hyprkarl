import QtQuick

QtObject {
  id: root

  property Item navigationRoot: null
  property Flickable viewport: null
  readonly property rect currentSectionRect: calculateSectionRect()
  readonly property rect currentSectionBounds: calculateSectionContainerRect(
    "navigationSectionBounds")
  readonly property rect currentContentBounds: calculateSectionContainerRect(
    "navigationContentBounds")

  function collectFocusItems(parent: Item, result: var): void {
    if (!parent) return
    for (const child of parent.children) {
      if (child.activeFocusOnTab === true
          && child.visible && child.enabled
          && child.width > 0 && child.height > 0) {
        result.push(child)
      }
      collectFocusItems(child, result)
    }
  }

  function collectSectionItems(parent: Item, section: string, result: var): void {
    if (!parent) return
    for (const child of parent.children) {
      if (child.visible && child.width > 0 && child.height > 0
          && child.navigationSection === section) {
        result.push(child)
      }
      collectSectionItems(child, section, result)
    }
  }

  function itemCenter(item: Item): point {
    return item.mapToItem(navigationRoot, item.width / 2, item.height / 2)
  }

  function navigationSection(item: Item): string {
    return item.navigationSection || "main"
  }

  function navigationSelected(item: Item): bool {
    return item.navigationSelected === true
  }

  function sectionEntry(items: var, section: string): Item {
    return items.find(item => navigationSection(item) === section
      && navigationSelected(item))
      ?? items.find(item => navigationSection(item) === section)
      ?? null
  }

  function calculateSectionContainerRect(propertyName: string): rect {
    if (!navigationRoot || NavigationState.currentSection.length === 0) {
      return Qt.rect(0, 0, 0, 0)
    }

    const items = []
    collectSectionItems(navigationRoot, NavigationState.currentSection, items)
    if (items.length === 0) return Qt.rect(0, 0, 0, 0)

    let ancestor = items[0]
    while (ancestor) {
      if (ancestor[propertyName] !== undefined) {
        const source = ancestor[propertyName]
        const topLeft = ancestor.mapToItem(navigationRoot, source.x, source.y)
        const bottomRight = ancestor.mapToItem(
          navigationRoot,
          source.x + source.width,
          source.y + source.height
        )
        return Qt.rect(
          topLeft.x,
          topLeft.y,
          bottomRight.x - topLeft.x,
          bottomRight.y - topLeft.y
        )
      }
      if (ancestor === navigationRoot) break
      ancestor = ancestor.parent
    }
    return Qt.rect(0, 0, 0, 0)
  }

  function calculateSectionRect(): rect {
    if (!navigationRoot || NavigationState.currentSection.length === 0) {
      return Qt.rect(0, 0, 0, 0)
    }

    const items = []
    collectSectionItems(navigationRoot, NavigationState.currentSection, items)
    if (items.length === 0) return Qt.rect(0, 0, 0, 0)

    let left = Infinity
    let top = Infinity
    let right = -Infinity
    let bottom = -Infinity
    for (const item of items) {
      const point = item.mapToItem(navigationRoot, 0, 0)
      left = Math.min(left, point.x)
      top = Math.min(top, point.y)
      right = Math.max(right, point.x + item.width)
      bottom = Math.max(bottom, point.y + item.height)
    }
    return Qt.rect(left, top, right - left, bottom - top)
  }

  function focusItems(): var {
    const items = []
    collectFocusItems(navigationRoot, items)
    items.sort((left, right) => {
      const leftCenter = itemCenter(left)
      const rightCenter = itemCenter(right)
      return Math.abs(leftCenter.y - rightCenter.y) > 1
        ? leftCenter.y - rightCenter.y
        : leftCenter.x - rightCenter.x
    })
    return items
  }

  function focusedItem(items: var): Item {
    return items.includes(NavigationState.currentItem)
      ? NavigationState.currentItem
      : items.find(item => item.activeFocus) ?? null
  }

  function revealItem(item: Item): void {
    if (!viewport) return
    const top = item.mapToItem(viewport, 0, 0).y
    const bottom = top + item.height
    let offset = 0
    if (top < 0) offset = top
    else if (bottom > viewport.height) offset = bottom - viewport.height
    const maximum = Math.max(0, viewport.contentHeight - viewport.height)
    viewport.contentY = Math.max(0,
      Math.min(maximum, viewport.contentY + offset))
  }

  function focusItem(item: Item, reason: int): void {
    if (!item) return
    NavigationState.useKeyboard(item, reason, navigationSection(item))
    Qt.callLater(() => revealItem(item))
  }

  function focusInitialItem(): void {
    const items = focusItems()
    if (items.length === 0) return
    const initialSection = navigationSection(
      items.find(item => navigationSection(item) !== "header") ?? items[0])
    const initial = sectionEntry(items, initialSection)
    NavigationState.select(initial, true, initialSection)
    initial.forceActiveFocus(Qt.TabFocusReason)
    Qt.callLater(() => revealItem(initial))
  }

  function moveSection(direction: int): void {
    const items = focusItems()
    if (items.length === 0) return
    const current = focusedItem(items)
    if (!current) {
      focusInitialItem()
      return
    }

    const sections = []
    for (const item of items) {
      const section = navigationSection(item)
      if (!sections.includes(section)) sections.push(section)
    }
    const currentIndex = sections.indexOf(navigationSection(current))
    const nextIndex = (currentIndex + direction + sections.length)
      % sections.length
    const nextSection = sections[nextIndex]
    focusItem(sectionEntry(items, nextSection),
      direction > 0 ? Qt.TabFocusReason : Qt.BacktabFocusReason)
  }

  function moveSpatial(horizontal: int, vertical: int): void {
    const items = focusItems()
    if (items.length === 0) return
    const current = focusedItem(items)
    if (!current) {
      focusInitialItem()
      return
    }

    const section = navigationSection(current)
    const origin = itemCenter(current)
    let best = null
    let bestScore = Infinity
    for (const candidate of items) {
      if (candidate === current || navigationSection(candidate) !== section) continue
      const center = itemCenter(candidate)
      const dx = center.x - origin.x
      const dy = center.y - origin.y
      const primary = horizontal !== 0 ? dx * horizontal : dy * vertical
      if (primary <= 1) continue
      const cross = horizontal !== 0 ? Math.abs(dy) : Math.abs(dx)
      const score = primary + cross * 2
      if (score >= bestScore) continue
      best = candidate
      bestScore = score
    }
    if (best) focusItem(best, Qt.ShortcutFocusReason)
  }

  function handleKey(event): bool {
    if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
      const backwards = event.key === Qt.Key_Backtab
        || (event.modifiers & Qt.ShiftModifier)
      moveSection(backwards ? -1 : 1)
    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
      moveSpatial(0, -1)
    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
      moveSpatial(0, 1)
    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
      moveSpatial(-1, 0)
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
      moveSpatial(1, 0)
    } else {
      return false
    }
    return true
  }
}
