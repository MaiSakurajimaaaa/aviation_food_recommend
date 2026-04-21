export interface FlightInfo {
  id: number
  flightNumber: string
  departure: string
  destination: string
  departureTime?: string
  arrivalTime?: string
  durationMinutes?: number
  mealCount?: number
  selectionDeadline?: string
  status?: number
}

export interface UserPreference {
  mealTypePreferences?: string
  flavorPreferences?: string
  dietaryNotes?: string
}

export interface RecommendationDish {
  dishId: number
  dishName: string
  pic?: string
  detail?: string
  mealType?: number
  flavorTags?: string
  score?: number
  explainReason?: string
  fallbackLevel?: number
}

export interface RecommendationTopItem {
  dishId: number
  dishName: string
  selectCount: number
}

export interface AnnouncementItem {
  id: number
  flightId?: number
  title: string
  content: string
  status?: number
  createUser?: number
  createTime?: string
  updateTime?: string
}

export interface MealSelectResult {
  flightId: number
  dishId: number
  mealOrder?: number
  selectedAt: string
  modified: boolean
  selectionDeadline?: string
}

export interface PendingRatingInfo {
  ratingTaskId?: number
  logId: number
  flightId: number
  ratingStatus?: 'PENDING' | 'DEFERRED' | 'SUBMITTED' | 'EXPIRED'
  deferCount?: number
  nextRemindAt?: string
  expireAt?: string
  dishId?: number
  flightNumber?: string
  departure?: string
  destination?: string
  departureTime?: string
  arrivalTime?: string
  recommendedDishes?: string
}

export interface RecommendConfirmPayload {
  dishId: number
  mealOrder?: number
  mealOrderLabel?: string
  dishName: string
  detail?: string
  mealType?: number
  flavorTags?: string
  score?: number
  explainReason?: string
  fallbackLevel?: number
  flightNumber?: string
  departure?: string
  destination?: string
  selectionDeadline?: string
}
