import request from '@/utils/request' // 引入自定义的axios函数
import type { DishPageQuery, DishUpsertPayload } from '@/types/aviation'
import type { DishItem } from '@/types/aviation'
import type { ApiPageResult, ApiResult } from '@/types/http'

/**
 * 添加菜品
 * @param params 添加菜品的DTO对象
 * @returns
 */
export const addDishAPI = (params: DishUpsertPayload) => {
  return request<ApiResult<null>>({
    url: '/dish',
    method: 'post',
    data: { ...params }
  })
}

/**
 * 获取菜品分页列表
 * @param params pageData
 * @returns
 */
export const getDishPageListAPI = (params: DishPageQuery) => {
  return request<ApiResult<ApiPageResult<any>>>({
    url: '/dish/page',
    method: 'get',
    params
  })
}

/**
 * 根据id获取菜品信息，用于回显
 * @param id 菜品id
 * @returns
 */
export const getDishByIdAPI = (id: number) => {
  return request<ApiResult<any>>({
    url: `/dish/${id}`,
    method: 'get'
  })
}

/**
 * 修改菜品信息
 * @param params 更新菜品信息的DTO对象
 * @returns
 */
export const updateDishAPI = (params: DishUpsertPayload) => {
  return request<ApiResult<null>>({
    url: '/dish',
    method: 'put',
    data: { ...params }
  })
}

/**
 * 修改菜品状态
 * @param params 菜品id
 * @returns
 */
export const updateDishStatusAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/dish/status/${id}`,
    method: 'put'
  })
}

/**
 * 根据ids批量删除菜品
 * @param ids 菜品ids
 * @returns
 */
export const deleteDishesAPI = (ids: string) => {
  return request<ApiResult<null>>({
    url: '/dish',
    method: 'delete',
    params: { ids }
  })
}

