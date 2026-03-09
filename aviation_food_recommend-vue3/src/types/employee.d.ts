export type UserInfo = {
  id: number
  account: string
  token: string
}

export type EmployeeLoginDTO = {
  account: string
  password: string
}

export type EmployeeFixPwdDTO = {
  oldPwd: string
  newPwd: string
}

export type EmployeePageQuery = {
  name?: string
  page: number
  pageSize: number
}

export type EmployeeUpsertDTO = {
  id?: number
  name: string
  account: string
  password?: string
  phone?: string
  age?: number | string
  gender?: number | string
  pic?: string
  status?: number
}

export type EmployeeItem = {
  id: number
  name: string
  account: string
  phone?: string
  age?: number | string
  gender?: number | string
  pic?: string
  status: number
  updateTime: string
}