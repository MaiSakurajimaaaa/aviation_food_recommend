const MAX_MEAL_COUNT = 3

export interface MealSelectionProgress {
  totalMealCount: number
  completedMealOrders: number[]
  completedCount: number
  remainingMealOrders: number[]
  isFullySelected: boolean
}

interface MealSelectionBaseInput {
  history: Array<Record<string, unknown>>
  flightId?: number | null
  mealCount?: number | null
}

interface MealOrderCheckInput extends MealSelectionBaseInput {
  mealOrder?: number | null
}

const parseFlightId = (value: unknown) => {
  const num = Number(value)
  return Number.isNaN(num) ? undefined : num
}

const parseNumeric = (value: unknown) => {
  const num = Number(value)
  return Number.isNaN(num) ? 0 : num
}

export const normalizeMealCount = (mealCount?: number | null) => {
  if (!mealCount || mealCount <= 0) return 1
  return Math.min(Math.floor(mealCount), MAX_MEAL_COUNT)
}

export const normalizeMealOrder = (mealOrder?: number | null, mealCount?: number | null) => {
  if (!mealOrder || mealOrder <= 0) return 1
  const parsedOrder = Math.floor(mealOrder)
  if (!mealCount || mealCount <= 0) return parsedOrder
  const totalMealCount = normalizeMealCount(mealCount)
  return Math.min(parsedOrder, totalMealCount)
}

export const resolveMealOrderFromFeedback = (feedback: unknown, mealCount?: number | null) => {
  const text = String(feedback ?? '')
  const matched = text.match(/mealOrder=(\d+)/)
  const parsedOrder = matched?.[1] ? Number(matched[1]) : 1
  return normalizeMealOrder(parsedOrder, mealCount)
}

const isManualSelectedFeedback = (feedback: unknown) => {
  return String(feedback ?? '').startsWith('MANUAL_SELECTED')
}

const getManualSelectionRowsByFlight = ({ history, flightId }: MealSelectionBaseInput) => {
  if (!flightId) return [] as Array<Record<string, unknown>>

  return history.filter((item) => {
    const row = item as Record<string, unknown>
    const rowFlightId = parseFlightId(row.flightId ?? row.flight_id)
    if (rowFlightId == null || rowFlightId !== flightId) return false
    const feedback = row.userFeedback ?? row.user_feedback
    return isManualSelectedFeedback(feedback)
  })
}

const getRowSortValue = (row: Record<string, unknown>) => {
  const idValue = parseNumeric(row.id)
  if (idValue > 0) return idValue

  const updateAt = Date.parse(String(row.updateTime ?? row.update_time ?? ''))
  if (!Number.isNaN(updateAt)) return updateAt

  const createAt = Date.parse(String(row.createTime ?? row.create_time ?? ''))
  if (!Number.isNaN(createAt)) return createAt

  return 0
}

export const getFlightMealSelectionProgress = ({ history, flightId, mealCount }: MealSelectionBaseInput): MealSelectionProgress => {
  const totalMealCount = normalizeMealCount(mealCount)
  const rows = getManualSelectionRowsByFlight({ history, flightId, mealCount: totalMealCount })
  const completedOrderSet = new Set<number>()

  rows.forEach((row) => {
    const feedback = row.userFeedback ?? row.user_feedback
    const order = resolveMealOrderFromFeedback(feedback, totalMealCount)
    completedOrderSet.add(order)
  })

  const completedMealOrders = Array.from(completedOrderSet).sort((a, b) => a - b)
  const remainingMealOrders = Array.from({ length: totalMealCount }, (_, idx) => idx + 1).filter((order) => !completedOrderSet.has(order))

  return {
    totalMealCount,
    completedMealOrders,
    completedCount: completedMealOrders.length,
    remainingMealOrders,
    isFullySelected: completedMealOrders.length >= totalMealCount,
  }
}

export const hasManualSelectionForMealOrder = ({ history, flightId, mealOrder, mealCount }: MealOrderCheckInput) => {
  const totalMealCount = normalizeMealCount(mealCount && mealCount > 0 ? mealCount : mealOrder)
  const targetMealOrder = normalizeMealOrder(mealOrder, totalMealCount)
  const rows = getManualSelectionRowsByFlight({ history, flightId, mealCount: totalMealCount })

  return rows.some((row) => {
    const feedback = row.userFeedback ?? row.user_feedback
    const order = resolveMealOrderFromFeedback(feedback, totalMealCount)
    return order === targetMealOrder
  })
}

export const findLatestManualSelectionForMealOrder = ({ history, flightId, mealOrder, mealCount }: MealOrderCheckInput) => {
  const totalMealCount = normalizeMealCount(mealCount && mealCount > 0 ? mealCount : mealOrder)
  const targetMealOrder = normalizeMealOrder(mealOrder, totalMealCount)
  const rows = getManualSelectionRowsByFlight({ history, flightId, mealCount: totalMealCount })

  const matchedRows = rows.filter((row) => {
    const feedback = row.userFeedback ?? row.user_feedback
    const order = resolveMealOrderFromFeedback(feedback, totalMealCount)
    return order === targetMealOrder
  })

  if (!matchedRows.length) return null
  return [...matchedRows].sort((a, b) => getRowSortValue(b) - getRowSortValue(a))[0]
}
