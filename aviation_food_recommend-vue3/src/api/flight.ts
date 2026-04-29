import request from '@/utils/request'
import type {
  AnnouncementUpsertPayload,
  ExistingPassengerCandidateItem,
  FlightMealBindingUpsertPayload,
  FlightPassengerUpsertPayload,
  FlightUpsertPayload,
} from '@/types/aviation'
import type { ApiResult } from '@/types/http'
import type { AnnouncementItem, FlightItem, FlightMealBindingItem, FlightPassengerItem } from '@/types/aviation'

export const getFlightListAPI = () => {
  return request<ApiResult<FlightItem[]>>({
    url: '/flight/list',
    method: 'get'
  })
}

export const addFlightAPI = (data: FlightUpsertPayload) => {
  return request<ApiResult<null>>({
    url: '/flight',
    method: 'post',
    data
  })
}

export const updateFlightAPI = (data: FlightUpsertPayload) => {
  return request<ApiResult<null>>({
    url: '/flight',
    method: 'put',
    data
  })
}

export const deleteFlightAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/flight/${id}`,
    method: 'delete'
  })
}

export const getFlightPassengersAPI = (flightId: number) => {
  return request<ApiResult<FlightPassengerItem[]>>({
    url: `/flight/passengers/${flightId}`,
    method: 'get'
  })
}

export const searchFlightPassengersAPI = (params: {
  flightNumber?: string
  name?: string
  idNumber?: string
}) => {
  return request<ApiResult<FlightPassengerItem[]>>({
    url: '/flight/passengers',
    method: 'get',
    params,
  })
}

export const addFlightPassengerAPI = (data: FlightPassengerUpsertPayload) => {
  return request<ApiResult<null>>({
    url: '/flight/passenger',
    method: 'post',
    data,
  })
}

export const searchExistingFlightPassengersAPI = (params: { keyword?: string; limit?: number }) => {
  return request<ApiResult<ExistingPassengerCandidateItem[]>>({
    url: '/flight/passenger/search',
    method: 'get',
    params,
  })
}

export const updateFlightPassengerAPI = (data: FlightPassengerUpsertPayload) => {
  return request<ApiResult<null>>({
    url: '/flight/passenger',
    method: 'put',
    data,
  })
}

export const deleteFlightPassengerAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/flight/passenger/${id}`,
    method: 'delete',
  })
}

export const getFlightMealsAPI = (flightNumber: string) => {
  return request<ApiResult<FlightMealBindingItem[]>>({
    url: `/flight/meals/${flightNumber}`,
    method: 'get',
  })
}

export const addFlightMealAPI = (data: FlightMealBindingUpsertPayload) => {
  return request<ApiResult<null>>({
    url: '/flight/meal',
    method: 'post',
    data,
  })
}

export const updateFlightMealAPI = (data: FlightMealBindingUpsertPayload) => {
  return request<ApiResult<null>>({
    url: '/flight/meal',
    method: 'put',
    data,
  })
}

export const deleteFlightMealAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/flight/meal/${id}`,
    method: 'delete',
  })
}

export const getAnnouncementListAPI = (flightId?: number) => {
  return request<ApiResult<AnnouncementItem[]>>({
    url: '/announcement/list',
    method: 'get',
    params: { flightId }
  })
}

export const addAnnouncementAPI = (data: AnnouncementUpsertPayload) => {
  return request<ApiResult<null>>({
    url: '/announcement',
    method: 'post',
    data
  })
}

export const updateAnnouncementAPI = (data: AnnouncementUpsertPayload) => {
  return request<ApiResult<null>>({
    url: '/announcement',
    method: 'put',
    data
  })
}

export const deleteAnnouncementAPI = (id: number) => {
  return request<ApiResult<null>>({
    url: `/announcement/${id}`,
    method: 'delete'
  })
}
