import request from '@/utils/request'
import type { UserMealSelectionItem, UserMealSelectionQuery } from '@/types/aviation'
import type { ApiResult } from '@/types/http'

export const getUserMealSelectionListAPI = (params: UserMealSelectionQuery) => {
  return request<ApiResult<UserMealSelectionItem[]>>({
    url: '/user-meal/list',
    method: 'get',
    params,
  })
}
