import request from '@/utils/request'
import type { ApiResult } from '@/types/http'

type OrderPageParams = {
  page?: number
  pageSize?: number
  number?: string
  phone?: string
  status?: number | string
  beginTime?: string | Date
  endTime?: string | Date
}

type OrderIdParams = {
  id?: number | string
}

type OrderDetailParams = {
  orderId: number | string
}

type OrderRejectOrCancelParams = {
  id?: number | string
  cancelReason?: string
  rejectionReason?: string
}

// 查询列表页接口
export const getOrderDetailPageAPI = (params: OrderPageParams) => {
  return request<ApiResult<any>>({
    url: '/order/conditionSearch',
    method: 'get',
    params
  })
}

// 查看接口
export const queryOrderDetailByIdAPI = (params: OrderDetailParams) => {
  return request<ApiResult<any>>({
    url: `/order/details/${params.orderId}`,
    method: 'get'
  })
}

// 派送接口
export const deliveryOrderAPI = (params: OrderIdParams) => {
  return request<ApiResult<null>>({
    url: `/order/delivery/${params.id}`,
    method: 'put'
  })
}

// 完成接口
export const completeOrderAPI = (params: OrderIdParams) => {
  return request<ApiResult<null>>({
    url: `/order/complete/${params.id}`,
    method: 'put'
  })
}

// 订单取消
export const orderCancelAPI = (params: OrderRejectOrCancelParams) => {
  return request<ApiResult<null>>({
    url: '/order/cancel',
    method: 'put',
    data: { ...params }
  })
}

// 接单
export const orderAcceptAPI = (params: OrderIdParams) => {
  return request<ApiResult<null>>({
    url: '/order/confirm',
    method: 'put',
    data: { ...params }
  })
}

// 拒单
export const orderRejectAPI = (params: OrderRejectOrCancelParams) => {
  return request<ApiResult<null>>({
    url: '/order/reject',
    method: 'put',
    data: { ...params }
  })
}

// 获取待处理，待派送，派送中数量
export const getOrderListByAPI = () => {
  return request<ApiResult<any>>({
    url: '/order/statistics',
    method: 'get'
  })
}
