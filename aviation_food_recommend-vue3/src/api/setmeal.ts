import request from '@/utils/request' // 引入自定义的axios函数
import type { ApiPageResult, ApiResult } from '@/types/http'

type SetmealDishItem = {
  dishId: number
  copies: number
  name?: string
}

type SetmealUpsertParams = {
  id?: number
  name: string
  categoryId: number | string
  status?: number | string
  detail?: string
  pic?: string
  setmealDishes?: SetmealDishItem[]
}

type SetmealPageParams = {
  page: number
  pageSize: number
  name?: string
  categoryId?: number | string
  status?: number | string
}

type SetmealItem = {
  id: number
  name: string
  categoryId: number
  status: number
  detail?: string
  pic?: string
}

/**
 * 添加套餐
 * @param params 添加套餐的DTO对象
 * @returns
 */
export const addSetmealAPI = (params: SetmealUpsertParams) => {
  return request<ApiResult<null>>({
    url: '/setmeal',
    method: 'post',
    data: { ...params }
  })
}

/**
 * 获取套餐分页列表
 * @param params pageData
 * @returns
 */
export const getSetmealPageListAPI = (params: SetmealPageParams) => {
  return request<ApiResult<ApiPageResult<any>>>({
    url: '/setmeal/page',
    method: 'get',
    params
  })
}

/**
 * 根据id获取套餐信息，用于回显
 * @param id 套餐id
 * @returns
 */
export const getSetmealByIdAPI = (id: number) => {
  return request<ApiResult<any>>({
    url: `/setmeal/${id}`,
    method: 'get'
  })
}

/**
 * 修改套餐信息
 * @param params 更新套餐信息的DTO对象
 * @returns
 */
export const updateSetmealAPI = (params: SetmealUpsertParams) => {
  return request<ApiResult<null>>({
    url: '/setmeal',
    method: 'put',
    data: { ...params }
  })
}

/**
 * 修改套餐状态
 * @param params 套餐id
 * @returns
 */
export const updateSetmealStatusAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/setmeal/status/${id}`,
    method: 'put'
  })
}

/**
 * 根据ids批量删除套餐
 * @param ids 套餐ids
 * @returns
 */
export const deleteSetmealsAPI = (ids: string) => {
  return request<ApiResult<null>>({
    url: '/setmeal',
    method: 'delete',
    params: { ids }
  })
}
