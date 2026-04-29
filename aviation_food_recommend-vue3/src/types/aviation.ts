export interface DashboardStats {
  recommendCount: number
  preferenceUserCount: number
  selectionCount: number
  avgRating: number
}

export interface FlightItem {
  id: number
  flightNumber: string
  departure: string
  destination: string
  departureTime?: string
  arrivalTime?: string
  durationMinutes: number
  mealCount: number
  mealTimes?: string
  selectionDeadline?: string
  status: number
}

export interface FlightUpsertPayload {
  id?: number
  flightNumber: string
  departure: string
  destination: string
  departureTime?: string
  arrivalTime?: string
  durationMinutes: number
  selectionDeadline?: string
  mealCount?: number
  mealTimes?: string
  status?: number
}

export interface RatingCenterDashboard {
  totalCount: number
  pendingCount: number
  deferredCount: number
  submittedCount: number
  expiredCount: number
  avgScore: number
  submitRate: number
}

export interface RatingCenterTaskItem {
  id: number
  userId: number
  userName: string
  idNumber?: string
  flightId: number
  flightNumber?: string
  departure?: string
  destination?: string
  departureTime?: string
  arrivalTime?: string
  ratingStatus: 'PENDING' | 'DEFERRED' | 'SUBMITTED' | 'EXPIRED'
  ratingScore?: number
  deferCount?: number
  nextRemindAt?: string
  submittedAt?: string
  expireAt?: string
  updateTime?: string
}

export interface AnnouncementItem {
  id: number
  flightId?: number
  title: string
  content: string
  status: number
}

export interface AnnouncementUpsertPayload {
  id?: number
  flightId?: number
  title: string
  content: string
  status: number
}

export interface FlightPassengerItem {
  userId: number
  name: string
  idNumber?: string
  age?: number
  phone?: string
  gender?: string
  cabinType?: number
  cabinTypeLabel?: string
  preferenceCompleted: number
  bindStatus: string
  mealSelected?: string
  flightId?: number
  flightNumber?: string
  departure?: string
  destination?: string
}

export interface FlightPassengerUpsertPayload {
  id?: number
  sourceType?: number
  existingUserId?: number
  flightId: number
  name: string
  idNumber?: string
  phone?: string
  gender?: number
  cabinType?: number
  preferenceCompleted?: number
}

export interface ExistingPassengerCandidateItem {
  userId: number
  name: string
  idNumber?: string
  phone?: string
  gender?: string
  cabinType?: number
  cabinTypeLabel?: string
  preferenceCompleted?: number
  currentFlightId?: number
}

export interface FlightMealBindingItem {
  id: number
  flightId: number
  flightNumber: string
  departure: string
  destination: string
  dishId: number
  dishName: string
  dishStatus?: number
  dishSource: number
  cabinType?: number
  sort: number
}

export interface FlightMealBindingUpsertPayload {
  id?: number
  flightNumber: string
  dishId: number
  dishSource?: number
  cabinType?: number
  sort?: number
}

export interface DishItem {
  id: number
  name: string
  pic?: string
  detail?: string
  categoryId: number
  mealType?: number
  flavorTags?: string
  stock?: number
  status: number
}

export interface DishUpsertPayload {
  id?: number
  name: string
  detail: string
  pic: string
  categoryId: number
  status: number
  mealType: number
  flavorTags: string
  stock: number
  flavors: unknown[]
}

export interface DishPageQuery {
  name?: string
  categoryId?: number | string
  status?: number | string
  type?: number | string
  page: number
  pageSize: number
}

export interface CategoryItem {
  id: number
  name: string
}

export interface UserMealSelectionItem {
  userId: number
  userName: string
  idNumber?: string
  phone?: string
  flightId?: number
  flightNumber?: string
  departure?: string
  destination?: string
  orderId: number
  orderNumber: string
  orderStatus: number
  orderTime?: string
  dishId?: number
  dishName?: string
  dishFlavor?: string
  dishCount?: number
}

export interface UserMealSelectionQuery {
  flightNumber?: string
  name?: string
  idNumber?: string
}

export interface UserMealDemandItem {
  dishName: string
  demandCount: number
}

export interface UserMealStatistics {
  flightNumber: string
  totalOrders: number
  selectedOrders: number
  unselectedOrders: number
  unrecordedOrders: number
  totalDishDemand: number
  distinctDishCount: number
  dishDemandList: UserMealDemandItem[]
}
