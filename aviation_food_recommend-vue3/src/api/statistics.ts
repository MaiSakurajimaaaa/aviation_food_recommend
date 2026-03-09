import request from '@/utils/request' // 引入自定义的axios函数
import type { ApiResult } from '@/types/http'

type DateRangeParams = {
  start?: string
  end?: string
  begin?: string
}

type DateParams = {
  date: string
}

type TypeDateParams = {
  type: number | string
  date: string
}

type TypeDateRangeParams = {
  type: number | string
  start: string
  end: string
}

/**
 * chart数据
 */

// 营业额统计
export const getTurnoverStatisticsAPI = (params: DateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/turnoverStatistics`,
    method: 'get',
    params
  })
}

// 用户统计
export const getUserStatisticsAPI = (params: DateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/userStatistics`,
    method: 'get',
    params
  })
}

// 订单统计
export const getOrderStatisticsAPI = (params: DateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/orderStatistics`,
    method: 'get',
    params
  })
}

// 销量排名TOP10
export const getTop10StatisticsAPI = (params: DateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/top10Statistics`,
    method: 'get',
    params
  })
}

// 数据概览
export const getDataOverViewAPI = (params: DateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/dataOverView`,
    method: 'get',
    params
  })
}

// 导出
export const exportInforAPI = () => {
  return request<Blob>({
    url: '/report/export',
    method: 'get',
    responseType: "blob" // 告诉浏览器预期响应的数据类型为二进制数据，而不是默认的 JSON 或纯文本
    // blob 表示二进制大对象，可以是图像、视频、音频、PDF 文件等
  })
}




// 逆天数据，不知道是啥...

// 获取当日销售数据 -> 顶部数据
export const getDataesAPI = (params: DateParams) => {
  return request<ApiResult<any>>({
    url: `/report/dayCollect/${params.date}`,
    method: 'get'
  })
}

// 获取当日销售数据 -> 顶部数据 - 营收概况
export const getChartsDataesAPI = (params: DateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/dayCollect/${params.start}/${params.end}`,
    method: 'get'
  })
}

// 获取当日销售趋势数据（24小时）-> 销售趋势
export const getDayDataesAPI = (params: TypeDateParams) => {
  return request<ApiResult<any>>({
    url: `/report/hourCollect/${params.type}/${params.date}`,
    method: 'get'
  })
}

// 收款类型数据汇总 -> 店内收款构成 - 当日
export const getDayPayTypeAPI = (params: DateParams) => {
  return request<ApiResult<any>>({
    url: `/report/payTypeCollect/${params.date}`,
    method: 'get'
  })
}

// 获取当日各种优惠类型数据汇总 -> 优惠指标
export const getprivilegeAPI = (params: DateParams) => {
  return request<ApiResult<any>>({
    url: `/report/privilegeCollect/${params.date}`,
    method: 'get'
  })
}

// 获取菜品分类销售排行 - 菜品分类占比 -当日
export const getSalesRankingAPI = (params: TypeDateParams) => {
  return request<ApiResult<any>>({
    url: `/report/categoryCollect/${params.type}/${params.date}`,
    method: 'get'
  })
}

// 获取当日菜品销售排行
export const getDayRankingAPI = (params: DateParams) => {
  return request<ApiResult<any>>({
    url: `/report/currentDishRank/${params.date}`,
    method: 'get'
  })
}


// 获取一定日期之内的销售趋势 - 销售趋势 图
export const getTimeQuantumDataesAPI = (params: TypeDateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/dayAmountCollect/${params.type}/${params.start}/${params.end}`,
    method: 'get'
  })
}

// 获取时间范围之内的各种收款类型数据汇总 - 店内收款构成 - 时间段
export const getTimeQuantumReceivablesAPI = (params: DateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/datePayTypeCollect/${params.start}/${params.end}`,
    method: 'get'
  })
}

// 获取时间范围之内的菜品类别销售汇总 -  菜品分类占比 - 时间段
export const getTimeQuantumTypeAPI = (params: TypeDateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/dateCategoryCollect/${params.type}/${params.start}/${params.end}`,
    method: 'get'
  })
}

// 获取时间范围之内的菜品销售排行 - 菜品销售排行
export const getTimeQuantumDishesAPI = (params: DateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/dishRankForDate/${params.start}/${params.end}`,
    method: 'get'
  })
}

// 获取时间范围之内的优惠指标汇总数据 - 顶部信息
export const getTimeQuantumDiscountAPI = (params: DateRangeParams) => {
  return request<ApiResult<any>>({
    url: `/report/privilegeByDate/${params.start}/${params.end}`,
    method: 'get'
  })
}
