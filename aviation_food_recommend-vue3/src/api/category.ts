import request from '@/utils/request'
import type { ApiPageResult, ApiResult } from '@/types/http'

type CategoryPageParams = {
  page: number
  pageSize: number
  type?: number | string
  name?: string
}

/**
 * 获取分类分页列表
 * @param params page,pageSize,type
 * @returns
 */
export const getCategoryPageListAPI = (params: CategoryPageParams) => {
  return request<ApiResult<ApiPageResult<any>>>({
    url: '/category/page',
    method: 'get',
    params
  })
}
