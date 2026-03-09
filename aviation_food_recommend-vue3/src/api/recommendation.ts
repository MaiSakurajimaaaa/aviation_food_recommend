import request from '@/utils/request'
import type { DashboardStats, RatingCenterDashboard, RatingCenterTaskItem } from '@/types/aviation'
import type { ApiResult } from '@/types/http'

export const getRecommendationDashboardAPI = () => {
  return request<ApiResult<DashboardStats>>({
    url: '/recommendation/dashboard',
    method: 'get'
  })
}

export const getRecommendationExceptionAPI = () => {
  return request<ApiResult<Array<{
    userId: number
    userName: string
    idNumber?: string
    currentFlightId?: number
    preferenceCompleted: number
    exceptionType: string
  }>>>({
    url: '/recommendation/exceptions',
    method: 'get'
  })
}

export const getRecommendationTopAPI = (size = 8, days?: number) => {
  return request<ApiResult<Array<{ dishId: number; dishName: string; selectCount: number }>>>({
    url: '/recommendation/top',
    method: 'get',
    params: {
      size,
      days,
    },
  })
}

export const getRatingCenterDashboardAPI = () => {
  return request<ApiResult<RatingCenterDashboard>>({
    url: '/recommendation/rating/dashboard',
    method: 'get',
  })
}

export const getRatingCenterListAPI = (params?: {
  status?: string
  flightNumber?: string
  userKeyword?: string
}) => {
  return request<ApiResult<RatingCenterTaskItem[]>>({
    url: '/recommendation/rating/list',
    method: 'get',
    params,
  })
}

export const reopenRatingTaskAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/recommendation/rating/${id}/reopen`,
    method: 'post',
  })
}

export const expireRatingTaskAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/recommendation/rating/${id}/expire`,
    method: 'post',
  })
}

export const deleteRatingTaskAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/recommendation/rating/${id}`,
    method: 'delete',
  })
}
