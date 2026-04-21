import { http } from '@/utils/http'
import type { ProfileDetail } from '@/types/user'

type UpdateUserPayload = {
  id: number
  name?: string
  phone?: string
  gender?: number
  pic?: string
  idNumber?: string
  cabinType?: number
}

// 根据id查询用户信息
export const getUserInfoAPI = (id: number) => {
  return http<ProfileDetail>({
    url: `/user/user/${id}`,
    method: 'GET',
  })
}

// 更新用户信息
export const updateUserAPI = (params: UpdateUserPayload) => {
  return http({
    url: '/user/user',
    method: 'PUT',
    data: params,
  })
}

export const getProfileTagsAPI = () => {
  return http<string[]>({
    url: '/user/profile/tags',
    method: 'GET',
  })
}
