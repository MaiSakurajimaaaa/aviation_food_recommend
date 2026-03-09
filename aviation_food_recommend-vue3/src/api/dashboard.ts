import request from '@/utils/request' // 引入自定义的axios函数
import type { ApiResult } from '@/types/http'

// 订单管理
export const getOrderDataAPI = () =>{
  return request<ApiResult<any>>({
    url: `/workspace/overviewOrders`,
    method: 'get'
  })
}
// 菜品总览
export const getOverviewDishesAPI = () => {
  return request<ApiResult<any>>({
    url: `/workspace/overviewDishes`,
    method: 'get'
  })
}

// 套餐总览
export const getSetMealStatisticsAPI = () => {
  return request<ApiResult<any>>({
    url: `/workspace/overviewSetmeals`,
    method: 'get'
  })
}

// 营业数据
export const getBusinessDataAPI = () => {
  return request<ApiResult<any>>({
    url: `/workspace/businessData`,
    method: 'get'
  })
}