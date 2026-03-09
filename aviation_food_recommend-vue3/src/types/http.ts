export interface ApiResult<T = unknown> {
  code: number
  msg: string
  data: T
}

export interface ApiPageResult<T> {
  total: number
  records: T[]
}
