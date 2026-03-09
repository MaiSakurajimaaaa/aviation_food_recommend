import { http } from '@/utils/http'
import type { FlightInfo } from '@/types/aviation'

export const getCurrentFlightAPI = () => {
  return http<FlightInfo | null>({
    method: 'GET',
    url: '/user/flight/current',
  })
}

export const getFlightListAPI = (idNumber?: string) => {
  return http<FlightInfo[]>({
    method: 'GET',
    url: '/user/flight/list',
    data: {
      idNumber,
    },
  })
}

export const bindFlightAPI = (flightId: number) => {
  return http({
    method: 'POST',
    url: '/user/flight/bind',
    data: { flightId },
  })
}
