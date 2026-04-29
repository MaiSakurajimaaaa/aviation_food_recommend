import { http } from '@/utils/http'
import type { AnnouncementItem, MealSelectResult, PendingRatingInfo, RecommendationDish, RecommendationTopItem } from '@/types/aviation'

export const getRecommendationListAPI = (params?: { mealType?: number; flavor?: string; mealOrder?: number; size?: number }) => {
  const query = Object.fromEntries(
    Object.entries(params || {}).filter(([, value]) => value !== undefined && value !== null),
  )
  return http<RecommendationDish[]>({
    method: 'GET',
    url: '/user/recommendation/list',
    data: query,
  })
}

export const getRecommendationHistoryAPI = () => {
  return http<Record<string, unknown>[]>({
    method: 'GET',
    url: '/user/recommendation/history',
  })
}

export const getPendingRatingAPI = () => {
  return http<PendingRatingInfo[]>({
    method: 'GET',
    url: '/user/recommendation/pending-rating',
  })
}

export const getAnnouncementListAPI = () => {
  return http<AnnouncementItem[]>({
    method: 'GET',
    url: '/user/announcement/list',
  })
}

export const getRecommendationTopAPI = (size = 5) => {
  return http<RecommendationTopItem[]>({
    method: 'GET',
    url: '/user/recommendation/top',
    data: { size },
  })
}

export const selectRecommendationMealAPI = (dishId: number, mealOrder?: number) => {
  return http<MealSelectResult>({
    method: 'POST',
    url: '/user/recommendation/select',
    data: { dishId, mealOrder },
  })
}

export const reportRecommendationClickAPI = (dishId: number, mealOrder?: number) => {
  return http<void>({
    method: 'POST',
    url: '/user/recommendation/click',
    data: { dishId, mealOrder },
  })
}

export const rateRecommendationAPI = (rating: number, flightId?: number) => {
  return http<void>({
    method: 'POST',
    url: '/user/recommendation/rate',
    data: {
      rating,
      flightId,
    },
  })
}

export const deferRecommendationAPI = (flightId?: number) => {
  return http<void>({
    method: 'POST',
    url: '/user/recommendation/rate/defer',
    data: {
      flightId,
    },
  })
}

export const getRatingHistoryAPI = () => {
  return http<Record<string, unknown>[]>({
    method: 'GET',
    url: '/user/recommendation/rating-history',
  })
}

export const getHistoryLogDetailAPI = (logId: number) => {
  return http<Record<string, any>>({
    method: 'GET',
    url: `/user/recommendation/history/${logId}`,
    suppressErrorToast: true,
  })
}

export const getRecommendationHistoryBreakdownAPI = (logId: number, timeout = 30000) => {
  return http<Record<string, any>>({
    method: 'GET',
    url: `/user/recommendation/history/${logId}/breakdown`,
    timeout,
    suppressErrorToast: true,
  })
}

export const resolveDishNamesAPI = (ids: number[]) => {
  return http<Record<number, string>>({
    method: 'GET',
    url: '/user/recommendation/dishes/resolve',
    data: { ids: ids.join(',') },
    suppressErrorToast: true,
  })
}
