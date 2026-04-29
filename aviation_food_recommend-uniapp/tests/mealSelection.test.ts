import { getFlightMealSelectionProgress, hasManualSelectionForMealOrder } from '../src/utils/mealSelection'

const assert = (condition: boolean, message: string) => {
  if (!condition) {
    throw new Error(message)
  }
}

const history: Array<Record<string, unknown>> = [
  {
    id: 1,
    flightId: 1001,
    userFeedback: 'MANUAL_SELECTED;dishId=201;mealOrder=1',
  },
  {
    id: 2,
    flight_id: 1001,
    user_feedback: 'CLICKED;dishId=202;mealOrder=2',
  },
  {
    id: 3,
    flightId: 1002,
    userFeedback: 'MANUAL_SELECTED;dishId=301;mealOrder=1',
  },
]

const progress = getFlightMealSelectionProgress({
  history,
  flightId: 1001,
  mealCount: 2,
})

assert(progress.totalMealCount === 2, 'totalMealCount should be 2')
assert(progress.completedCount === 1, 'completedCount should be 1')
assert(JSON.stringify(progress.completedMealOrders) === JSON.stringify([1]), 'completedMealOrders should be [1]')
assert(JSON.stringify(progress.remainingMealOrders) === JSON.stringify([2]), 'remainingMealOrders should be [2]')
assert(progress.isFullySelected === false, 'isFullySelected should be false')

assert(
  hasManualSelectionForMealOrder({
    history,
    flightId: 1001,
    mealOrder: 1,
  }) === true,
  'mealOrder 1 should be selected'
)

assert(
  hasManualSelectionForMealOrder({
    history,
    flightId: 1001,
    mealOrder: 2,
  }) === false,
  'mealOrder 2 should be unselected'
)

console.log('mealSelection tests passed')
