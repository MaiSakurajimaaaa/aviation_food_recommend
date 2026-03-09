import { http } from '@/utils/http'
import type { MealSelectResult, PendingRatingInfo, RecommendationDish, RecommendationTopItem } from '@/types/aviation'

export const getRecommendationListAPI = (params?: { mealType?: number; flavor?: string; size?: number }) => {
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
  return http<Array<{ id: number; title: string; content: string }>>({
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

export const selectRecommendationMealAPI = (dishId: number) => {
  return http<MealSelectResult>({
    method: 'POST',
    url: '/user/recommendation/select',
    data: { dishId },
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
