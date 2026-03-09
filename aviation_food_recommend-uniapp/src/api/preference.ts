import { http } from '@/utils/http'
import type { UserPreference } from '@/types/aviation'

export const getPreferenceAPI = () => {
  return http<UserPreference | null>({
    method: 'GET',
    url: '/user/preference',
  })
}

export const savePreferenceAPI = (data: UserPreference) => {
  return http({
    method: 'PUT',
    url: '/user/preference',
    data,
  })
}
