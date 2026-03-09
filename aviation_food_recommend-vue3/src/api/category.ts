import request from '@/utils/request' // 引入自定义的axios函数
import type { CategoryItem } from '@/types/aviation'
import type { ApiPageResult, ApiResult } from '@/types/http'

type CategoryUpsertParams = {
  id?: number
  name: string
  type: number | string
  sort: number | string
  status?: number | string
}

type CategoryPageParams = {
  page: number
  pageSize: number
  type?: number | string
  name?: string
}

/**
 * 添加分类
 * @param params 添加分类的DTO对象
 * @returns
 */
export const addCategoryAPI = (params: CategoryUpsertParams) => {
  return request<ApiResult<null>>({
    url: '/category',
    method: 'post',
    data: { ...params }
  })
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

/**
 * 根据id获取分类信息，用于回显
 * @param id 分类id
 * @returns
 */
export const getCategoryByIdAPI = (id: number) => {
  return request<ApiResult<any>>({
    url: `/category/${id}`,
    method: 'get'
  })
}

/**
 * 修改分类信息
 * @param params 更新分类信息的DTO对象
 * @returns
 */
export const updateCategoryAPI = (params: CategoryUpsertParams) => {
  return request<ApiResult<null>>({
    url: '/category',
    method: 'put',
    data: { ...params }
  })
}

/**
 * 修改分类状态
 * @param params 分类id
 * @returns
 */
export const updateCategoryStatusAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/category/status/${id}`,
    method: 'put'
  })
}

/**
 * 根据id删除分类
 * @param id 分类id
 * @returns
 */
export const deleteCategoryAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/category/${id}`,
    method: 'delete'
  })
}
