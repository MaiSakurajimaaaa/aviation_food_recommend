import { bindFlightAPI, getCurrentFlightAPI, getFlightListAPI } from '@/api/flight'
import { getUserInfoAPI } from '@/api/user'
import type { FlightInfo } from '@/types/aviation'
import { useAuthGuard } from './useAuthGuard'

export const useFlightContext = () => {
  const { userStore, ensureLogin } = useAuthGuard()

  const loadFlightContext = async () => {
    if (!ensureLogin()) {
      return {
        ok: false,
        currentFlight: null as FlightInfo | null,
        candidateFlights: [] as FlightInfo[],
      }
    }

    const userRes = await getUserInfoAPI(userStore.profile!.id)
    const idNumber = userRes.data?.idNumber
    if (!idNumber) {
      return {
        ok: false,
        currentFlight: null as FlightInfo | null,
        candidateFlights: [] as FlightInfo[],
      }
    }

    const [currentRes, candidateRes] = await Promise.all([getCurrentFlightAPI(), getFlightListAPI(idNumber)])
    let currentFlight = currentRes.data || null
    const candidateFlights = candidateRes.data || []

    if (!currentFlight && candidateFlights.length > 0) {
      const defaultFlight = candidateFlights[0]
      await bindFlightAPI(defaultFlight.id)
      currentFlight = defaultFlight
    }

    return {
      ok: !!currentFlight,
      currentFlight,
      candidateFlights,
    }
  }

  return {
    loadFlightContext,
  }
}
