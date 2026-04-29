import request from '@/utils/request'
import type { UserMealSelectionItem, UserMealSelectionQuery, UserMealStatistics } from '@/types/aviation'
import type { ApiResult } from '@/types/http'

export const getUserMealSelectionListAPI = (params: UserMealSelectionQuery) => {
  return request<ApiResult<UserMealSelectionItem[]>>({
    url: '/user-meal/list',
    method: 'get',
    params,
  })
}

export const getUserMealStatisticsAPI = (flightNumber: string) => {
  return request<ApiResult<UserMealStatistics>>({
    url: '/user-meal/statistics',
    method: 'get',
    params: { flightNumber },
  })
}
