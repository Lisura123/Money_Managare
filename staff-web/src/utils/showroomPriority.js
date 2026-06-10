// Flagship showroom prioritisation.
//
// The two flagship showrooms — CAMERALK (PVT) LTD and SONY ASIA PACIFIC (PVT) LTD —
// should always appear at the top of every showroom dropdown and be visually
// highlighted for easier selection.

export function isFlagshipShowroom(name) {
  if (!name) return false
  const upper = String(name).toUpperCase()
  return upper.includes('CAMERALK') || upper.includes('SONY')
}

// Returns a new array with flagship showrooms first (keeping their relative order),
// then the rest. `nameKey` is the property holding the showroom name.
export function prioritizeShowrooms(list, nameKey = 'name') {
  if (!Array.isArray(list)) return []
  const flagships = list.filter(s => isFlagshipShowroom(s?.[nameKey]))
  const others = list.filter(s => !isFlagshipShowroom(s?.[nameKey]))
  return [...flagships, ...others]
}

// Prefixes a star to flagship showroom names for emphasis inside <option> elements.
export function showroomOptionLabel(name) {
  return isFlagshipShowroom(name) ? `★ ${name}` : name
}
